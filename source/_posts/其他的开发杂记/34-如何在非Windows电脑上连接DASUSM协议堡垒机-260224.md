---
title: 如何在非Windows电脑上连接DASUSM协议堡垒机
category: 其他的开发杂记
date: 2026-02-24 18:00:00
---


# TL;DR
放寒假前，我们学校发了个小内服务器的堡垒机使用指南，这样就可以在校外访问校内资源了。但是有个问题啊，首先你自己证书懒得续签，但又愿意在手册里说大家记得无视风险继续访问，这就很离谱了。其次，按照手册要求，连接堡垒机需要用到`H*C SecPath`的专有软件`单点登录器`（而且仅支持非自由系统Windows）和`XShell 8`，这就很不GNU了，因为RMS曾经说过，[专有软件常常是恶意软件](https://www.gnu.org/proprietary/proprietary.html)。为了保护个人电脑的安全，同时为了能在除了Windows以外的任何操作系统上连接这个堡垒机，便诞生了此油猴脚本。


# 工作原理
## Overview
当你登录到运维审计系统后台后，选择要运维的机器，输入该机上你要运维的账号密码后，它会通过uri拉起`单点登录器`，然后由单点登录器解析URI，并通过启动参数来拉起`XShell 8`，使用网页登录的账号作为用户名、URI里的`token`作为ssh临时密码来登录堡垒机，堡垒机会因此给你直接登录到服务器上的该账户，当该临时密码对应的所有会话都断开后，临时密码会被吊销，不能再用。注意，单点登录器拉起XShell的时候，是把临时密码以***明文***的形式放在启动参数里拉起的，所以就可以用微软的[Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer)来看启动参数，然后直接ssh连接即可。


## 这个URI长什么样？
我们来看一段示例URI：
``` text
dasusm://eyJOT0RFX0NPTU1PTiI6eyJNb2RlIjoiMCIsIklzR2xvYmFsU2V0dGluZyI6IjAiLCJJUHY0IjoiMS4yLjMuNCIsIkFzc2V0SVB2NCI6IjEwLjEuMi4zIiwiUG9ydCI6IjYwMDIyIiwiQXNzZXRQb3J0IjoiMjIiLCJQcm90b2NvbCI6IlNTSCIsIkNsaWVudE5hbWUiOiIiLCJDbGllbnRQYXRoIjoiIiwiVXNlcm5hbWUiOiJteXN0dW5hbWUiLCJTU09Ub2tlbiI6IjExNDUxNCJ9fQ==/
```
对它后面的内容用`base64`解码后是这样的（我对它进行了格式化）：
``` json
{
    "NODE_COMMON": {
        "Mode": "0",
        "IsGlobalSetting": "0",
        "IPv4": "1.2.3.4",
        "AssetIPv4": "10.1.2.3",
        "Port": "60022",
        "AssetPort": "22",
        "Protocol": "SSH",
        "ClientName": "",
        "ClientPath": "",
        "Username": "myusername",
        "SSOToken": "114514"
    }
}
```


## 我不要临时密码也不要单点登录器
直接用你网页的账号+密码进行ssh登录即可，然后它会叫你选择要连接的主机，然后按提示输入用户名和密码即可。



# 油猴脚本
直接复制，然后在油猴插件的设置界面新建脚本，然后黏贴以下内容即可。
``` javascript
// ==UserScript==
// @name         DASUSM Link Password Extractor
// @namespace    https://x.com/realdonaldtrump
// @version      1.9.0
// @description  Intercept DASUSM SSO response, decode dasusm:// payload, and show/copy SSH login info.
// @author       you
// @match        *://*/*
// @grant        GM_setClipboard
// @grant        GM_getValue
// @grant        GM_setValue
// @run-at       document-start
// @license      GPL-3.0
// ==/UserScript==

(function () {
  'use strict';

  const TARGET_PATH = '/index.php/om/sso';
  const STYLE_ID = 'dasusm-extractor-style';
  const SETTINGS_FAB_ID = 'dasusm-extractor-settings-fab';
  const SETTINGS_POPUP_ID = 'dasusm-extractor-settings-popup';
  const HISTORY_POPUP_ID = 'dasusm-extractor-history-popup';
  const SSO_MSG_ID = 'ssomsg';
  const STORE_STRICT_INTERCEPT = 'dasusm_strict_intercept_v1';
  const STORE_CUSTOM_INTERCEPT_URL = 'dasusm_custom_intercept_url_v1';
  const GM_INFO_FALLBACK = (typeof GM_info !== 'undefined' && GM_info) ? GM_info : (globalThis && globalThis.GM_info);
  const SCRIPT_NAME = (GM_INFO_FALLBACK && GM_INFO_FALLBACK.script && GM_INFO_FALLBACK.script.name)
    ? String(GM_INFO_FALLBACK.script.name)
    : 'DASUSM Link Password Extractor';
  const SCRIPT_VER = (GM_INFO_FALLBACK && GM_INFO_FALLBACK.script && GM_INFO_FALLBACK.script.version)
    ? String(GM_INFO_FALLBACK.script.version)
    : 'unknown';
  const historyRecords = [];
  let pageFullyLoaded = document.readyState === 'complete';
  let ssoWarningDecision = null;
  let strictInterceptEnabled = gmGetValueSafe(STORE_STRICT_INTERCEPT, true);
  let customInterceptUrl = gmGetValueSafe(STORE_CUSTOM_INTERCEPT_URL, getDefaultInterceptUrl());

  try {
    console.info(`[${SCRIPT_NAME}] loaded v${SCRIPT_VER}`);
  } catch (_) {}

  function decodeBase64Unicode(str) {
    try {
      // Prefer modern decode path.
      const bytes = Uint8Array.from(atob(str), (c) => c.charCodeAt(0));
      return new TextDecoder('utf-8').decode(bytes);
    } catch (_) {
      // Fallback for older environments.
      return decodeURIComponent(
        atob(str)
          .split('')
          .map((c) => '%' + c.charCodeAt(0).toString(16).padStart(2, '0'))
          .join('')
      );
    }
  }

  function safeJsonParse(text) {
    try {
      return JSON.parse(text);
    } catch (_) {
      return null;
    }
  }

  function safeCopy(text) {
    if (!text) return;
    try {
      if (typeof GM_setClipboard === 'function') {
        GM_setClipboard(text);
        return;
      }
    } catch (_) {}

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).catch(() => {});
      return;
    }

    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.left = '-9999px';
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    try {
      document.execCommand('copy');
    } catch (_) {}
    ta.remove();
  }

  function gmGetValueSafe(key, fallback) {
    try {
      if (typeof GM_getValue === 'function') return GM_getValue(key, fallback);
    } catch (_) {}
    return fallback;
  }

  function gmSetValueSafe(key, value) {
    try {
      if (typeof GM_setValue === 'function') GM_setValue(key, value);
    } catch (_) {}
  }

  function getDefaultInterceptUrl() {
    return `https://${location.host}${TARGET_PATH}`;
  }

  function normalizeUrl(url) {
    try {
      const u = new URL(String(url || ''), location.href);
      u.hash = '';
      return u.href.replace(/\/+$/, '');
    } catch (_) {
      return String(url || '').trim().replace(/\/+$/, '');
    }
  }

  function getEffectiveInterceptUrl() {
    const custom = String(customInterceptUrl || '').trim();
    return custom || getDefaultInterceptUrl();
  }

  function parseDasusmUrl(uri) {
    if (typeof uri !== 'string' || !uri.toLowerCase().startsWith('dasusm://')) {
      return null;
    }

    let raw = uri.slice('dasusm://'.length);
    raw = raw.replace(/[\/\s]/g, '');
    raw = raw.replace(/-/g, '+').replace(/_/g, '/');

    while (raw.length % 4 !== 0) {
      raw += '=';
    }

    const decoded = decodeBase64Unicode(raw);
    return safeJsonParse(decoded);
  }

  function buildSshAlias(host, username) {
    const base = `dasusm-${username || 'user'}-${host || 'host'}`.toLowerCase();
    return base.replace(/[^a-z0-9._-]/g, '-').replace(/-+/g, '-');
  }

  function buildSshConfigEntry(host, port, username) {
    const alias = buildSshAlias(host, username);
    const p = port || '22';
    return [
      `Host ${alias}`,
      `  HostName ${host}`,
      `  Port ${p}`,
      `  User ${username}`,
      `  PubkeyAuthentication no`,
      `  IdentitiesOnly yes`,
      `  HostKeyAlgorithms +ssh-rsa`,
      `  PubkeyAcceptedAlgorithms +ssh-rsa`,
      `  MACs +hmac-sha1`,
      ``,
      `# 使用: ssh ${alias}`
    ].join('\n');
  }

  function buildSftpCmd(host, port, username) {
    return `sftp -P ${port || '22'} ${username}@${host}`;
  }

  function buildSftpCmdModern(host, port, username) {
    const sftpCmd = buildSftpCmd(host, port, username);
    return `${sftpCmd} -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o MACs=+hmac-sha1`;
  }

  function pickCoreNode(payload) {
    if (!payload || typeof payload !== 'object') return null;

    if (payload.NODE_COMMON && typeof payload.NODE_COMMON === 'object') {
      return payload.NODE_COMMON;
    }

    // Fallback: first object-like field.
    for (const key of Object.keys(payload)) {
      const value = payload[key];
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        return value;
      }
    }

    return null;
  }

  function ensureStyles() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = `
#dasusm-extractor-popup {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  background: linear-gradient(130deg, rgba(10, 18, 32, 0.7), rgba(15, 23, 42, 0.5), rgba(3, 105, 161, 0.32));
  background-size: 200% 200%;
  animation: dsm-mask-gradient 7s ease-in-out infinite;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}
#dasusm-extractor-popup .dsm-box {
  width: min(760px, calc(100vw - 24px));
  max-height: calc(100vh - 24px);
  overflow: auto;
  border-radius: 16px;
  background:
    radial-gradient(circle at 100% 0%, rgba(59,130,246,0.12), transparent 34%),
    radial-gradient(circle at 0% 100%, rgba(14,165,233,0.1), transparent 30%),
    linear-gradient(180deg, #ffffff 0%, #f7fbff 100%);
  border: 1px solid #d9e8ff;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.38);
  padding: 18px;
  color: #0f172a;
  font-family: "Consolas", "Menlo", "Monaco", monospace;
  animation: dsm-pop .18s ease-out;
}
@keyframes dsm-pop {
  from { opacity: 0; transform: translateY(8px) scale(0.985); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
@keyframes dsm-mask-gradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
#dasusm-extractor-popup .dsm-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 10px;
  border-bottom: 1px solid #e4edff;
}
#dasusm-extractor-popup .dsm-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}
#dasusm-extractor-popup .dsm-title {
  font-size: 16px;
  font-weight: 700;
}
#dasusm-extractor-popup .dsm-tag {
  font-size: 12px;
  color: #075985;
  background: linear-gradient(180deg, #ecfeff, #dff4ff);
  border: 1px solid #b5e7ff;
  border-radius: 999px;
  padding: 2px 9px;
}
#dasusm-extractor-popup .dsm-close,
#dasusm-extractor-popup .dsm-copy {
  border: 1px solid #cbd5e1;
  background: #fff;
  color: #0f172a;
  border-radius: 8px;
  cursor: pointer;
  font-size: 12px;
  padding: 5px 10px;
  transition: all .15s ease;
}
#dasusm-extractor-popup .dsm-copy {
  margin-left: 8px;
}
#dasusm-extractor-popup .dsm-info-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  margin-left: 8px;
  border-radius: 999px;
  border: 1px solid #93c5fd;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 700;
  cursor: help;
  user-select: none;
}
#dasusm-extractor-popup .dsm-close:hover,
#dasusm-extractor-popup .dsm-copy:hover {
  border-color: #93c5fd;
  background: #eff6ff;
}
#dasusm-extractor-popup .dsm-row {
  display: grid;
  grid-template-columns: 108px 1fr auto;
  align-items: start;
  gap: 10px;
  margin: 8px 0;
  border: 1px solid #dce7f7;
  background: linear-gradient(180deg, #ffffff, #fbfdff);
  border-radius: 10px;
  padding: 8px 10px;
  box-shadow: 0 1px 0 rgba(255,255,255,0.8) inset;
}
#dasusm-extractor-popup .dsm-key {
  font-weight: 700;
  color: #1e3a5f;
  padding-top: 1px;
}
#dasusm-extractor-popup .dsm-val {
  word-break: break-all;
  color: #0f172a;
  line-height: 1.45;
}
#dasusm-extractor-popup .dsm-action {
  text-align: right;
  white-space: nowrap;
}
#dasusm-extractor-popup .dsm-main-copy {
  margin-top: 12px;
  width: 100%;
  border: 1px solid #93c5fd;
  background: linear-gradient(180deg, #2f7df9 0%, #1d61d8 100%);
  color: #fff;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 700;
  padding: 9px 12px;
  transition: filter .15s ease;
  box-shadow: 0 10px 24px rgba(37, 99, 235, 0.25);
}
#dasusm-extractor-popup .dsm-main-copy:hover {
  filter: brightness(1.06);
}
#dasusm-extractor-popup .dsm-main-actions {
  margin-top: 12px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
#dasusm-extractor-popup .dsm-main-actions .dsm-main-copy {
  margin-top: 0;
}
#dasusm-extractor-popup .dsm-main-copy.dsm-main-copy-sftp {
  border-color: #7dd3fc;
  background: linear-gradient(180deg, #0ea5e9 0%, #0284c7 100%);
}
#dasusm-extractor-popup .dsm-collapsible-preview {
  color: #475569;
  font-size: 12px;
}
#dasusm-extractor-popup .dsm-collapsible-content {
  overflow: hidden;
  max-height: 0;
  opacity: 0;
  transform: translateY(-4px);
  transition: max-height .24s ease, opacity .2s ease, transform .24s ease;
}
#dasusm-extractor-popup .dsm-collapsible-content.is-expanded {
  max-height: 420px;
  opacity: 1;
  transform: translateY(0);
}
#dasusm-extractor-popup .dsm-hint {
  margin-top: 10px;
  color: #475569;
  font-size: 12px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 7px 9px;
}
@media (max-width: 640px) {
  #dasusm-extractor-popup .dsm-box {
    padding: 12px;
    border-radius: 12px;
  }
  #dasusm-extractor-popup .dsm-row {
    grid-template-columns: 1fr;
    gap: 6px;
  }
  #dasusm-extractor-popup .dsm-action {
    text-align: left;
  }
}
#${SETTINGS_FAB_ID} {
  position: fixed;
  right: 18px;
  bottom: 22px;
  z-index: 2147483646;
  width: 48px;
  height: 48px;
  border-radius: 999px;
  border: 1px solid #93c5fd;
  background: linear-gradient(180deg, #2f7df9 0%, #1d61d8 100%);
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 10px 24px rgba(37, 99, 235, 0.35);
}
#${SETTINGS_FAB_ID}:hover {
  filter: brightness(1.06);
}
#${SETTINGS_POPUP_ID} {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  background: linear-gradient(130deg, rgba(10, 18, 32, 0.7), rgba(15, 23, 42, 0.5), rgba(3, 105, 161, 0.32));
  background-size: 200% 200%;
  animation: dsm-mask-gradient 7s ease-in-out infinite;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  opacity: 0;
  transition: opacity .18s ease;
}
#${SETTINGS_POPUP_ID}.dsm-open {
  opacity: 1;
}
#${SETTINGS_POPUP_ID}.dsm-close {
  opacity: 0;
}
#${SETTINGS_POPUP_ID} .dsm-set-box {
  width: min(640px, calc(100vw - 24px));
  max-height: calc(100vh - 24px);
  overflow: auto;
  border-radius: 14px;
  background: #fff;
  border: 1px solid #d9e8ff;
  box-shadow: 0 18px 45px rgba(15, 23, 42, 0.3);
  padding: 14px;
  transform: translateY(8px) scale(0.985);
  opacity: 0;
  transition: transform .24s cubic-bezier(0.2, 0, 0, 1), opacity .2s ease;
}
#${SETTINGS_POPUP_ID}.dsm-open .dsm-set-box {
  transform: translateY(0) scale(1);
  opacity: 1;
}
#${SETTINGS_POPUP_ID}.dsm-close .dsm-set-box {
  transform: translateY(8px) scale(0.985);
  opacity: 0;
}
#${SETTINGS_POPUP_ID} .dsm-set-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}
#${SETTINGS_POPUP_ID} .dsm-set-row {
  margin-top: 10px;
  border: 1px solid #dce7f7;
  border-radius: 10px;
  background: #fbfdff;
  padding: 10px;
}
#${SETTINGS_POPUP_ID} .dsm-set-label {
  display: block;
  color: #0f172a;
  font-weight: 700;
  margin-bottom: 8px;
}
#${SETTINGS_POPUP_ID} .dsm-set-desc {
  color: #475569;
  font-size: 12px;
  margin-top: 6px;
}
#${SETTINGS_POPUP_ID} .dsm-set-input {
  width: 100%;
  box-sizing: border-box;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 7px 9px;
  font-size: 12px;
  color: #0f172a;
}
#${SETTINGS_POPUP_ID} .dsm-set-input-wrap {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
  align-items: center;
}
#${SETTINGS_POPUP_ID} .dsm-set-clear-btn {
  border: 1px solid #cbd5e1;
  background: #fff;
  color: #0f172a;
  border-radius: 8px;
  cursor: pointer;
  font-size: 12px;
  padding: 6px 10px;
}
#${SETTINGS_POPUP_ID} .dsm-set-clear-btn:hover {
  border-color: #93c5fd;
  background: #eff6ff;
}
#${SETTINGS_POPUP_ID} .dsm-set-collapsible {
  overflow: hidden;
  max-height: 180px;
  opacity: 1;
  transform: translateY(0);
  transition: max-height .22s ease, opacity .18s ease, transform .22s ease, margin-top .22s ease;
}
#${SETTINGS_POPUP_ID} .dsm-set-collapsible.is-collapsed {
  max-height: 0;
  opacity: 0;
  transform: translateY(-4px);
  margin-top: 0;
  padding-top: 0;
  padding-bottom: 0;
  border-width: 0;
}
#${SETTINGS_POPUP_ID} .dsm-set-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}
#${SETTINGS_POPUP_ID} .dsm-set-btn {
  border: 1px solid #cbd5e1;
  background: #fff;
  color: #0f172a;
  border-radius: 8px;
  cursor: pointer;
  font-size: 12px;
  padding: 6px 12px;
}
#${SETTINGS_POPUP_ID} .dsm-set-btn:hover {
  border-color: #93c5fd;
  background: #eff6ff;
}
#${HISTORY_POPUP_ID} {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  background: linear-gradient(130deg, rgba(10, 18, 32, 0.7), rgba(15, 23, 42, 0.5), rgba(3, 105, 161, 0.32));
  background-size: 200% 200%;
  animation: dsm-mask-gradient 7s ease-in-out infinite;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}
#${HISTORY_POPUP_ID} .dsm-his-box {
  width: min(760px, calc(100vw - 24px));
  max-height: calc(100vh - 24px);
  overflow: auto;
  border-radius: 14px;
  background: #fff;
  border: 1px solid #d9e8ff;
  box-shadow: 0 18px 45px rgba(15, 23, 42, 0.3);
  padding: 14px;
}
#${HISTORY_POPUP_ID} .dsm-his-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
#${HISTORY_POPUP_ID} .dsm-his-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}
#${HISTORY_POPUP_ID} .dsm-his-tools {
  display: flex;
  gap: 8px;
}
#${HISTORY_POPUP_ID} .dsm-his-btn {
  border: 1px solid #cbd5e1;
  background: #fff;
  color: #0f172a;
  border-radius: 8px;
  cursor: pointer;
  font-size: 12px;
  padding: 5px 10px;
}
#${HISTORY_POPUP_ID} .dsm-his-btn:hover {
  border-color: #93c5fd;
  background: #eff6ff;
}
#${HISTORY_POPUP_ID} .dsm-his-item {
  border: 1px solid #dce7f7;
  background: linear-gradient(180deg, #ffffff, #fbfdff);
  border-radius: 10px;
  padding: 10px 12px;
  margin: 8px 0;
  overflow: hidden;
  max-height: 220px;
  transition: max-height .24s ease, opacity .2s ease, transform .24s ease, margin .24s ease, padding .24s ease;
}
#${HISTORY_POPUP_ID} .dsm-his-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}
#${HISTORY_POPUP_ID} .dsm-his-top-left {
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 0;
}
#${HISTORY_POPUP_ID} .dsm-his-time {
  color: #475569;
  font-size: 12px;
  white-space: nowrap;
}
#${HISTORY_POPUP_ID} .dsm-his-host {
  color: #0f172a;
  font-weight: 700;
  font-size: 13px;
  line-height: 1.2;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-left: 0;
  transition: margin-left .22s ease, transform .22s ease;
}
#${HISTORY_POPUP_ID}.dsm-batch-mode .dsm-his-host {
  margin-left: 8px;
  transform: translateX(0);
}
#${HISTORY_POPUP_ID} .dsm-his-meta {
  margin-top: 4px;
  color: #334155;
  font-size: 12px;
  word-break: break-all;
}
#${HISTORY_POPUP_ID} .dsm-his-batch-tools {
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-height: 0;
  opacity: 0;
  transform: translateY(-4px);
  overflow: hidden;
  transition: max-height .24s ease, opacity .2s ease, transform .24s ease;
}
#${HISTORY_POPUP_ID}.dsm-batch-mode .dsm-his-batch-tools {
  max-height: 120px;
  opacity: 1;
  transform: translateY(0);
}
#${HISTORY_POPUP_ID} .dsm-his-btn-danger {
  border-color: #fecaca;
  background: #fff1f2;
  color: #b91c1c;
}
#${HISTORY_POPUP_ID} .dsm-his-item-select {
  display: inline-block;
  width: 0;
  height: 16px;
  margin: 0;
  padding: 0;
  border: 0;
  flex: 0 0 auto;
  cursor: pointer;
  accent-color: #2563eb;
  pointer-events: none;
}
#${HISTORY_POPUP_ID} .dsm-his-item-actions {
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
#${HISTORY_POPUP_ID} .dsm-his-item-actions .dsm-his-btn {
  padding: 4px 10px;
  font-size: 12px;
}
#${HISTORY_POPUP_ID} .dsm-his-item-select {
  opacity: 0;
  transform: translateX(-6px);
  transition: width .22s ease, margin-right .22s ease, opacity .18s ease, transform .22s ease;
}
#${HISTORY_POPUP_ID}.dsm-batch-mode .dsm-his-item-select {
  width: 16px;
  margin-right: 0;
  opacity: 1;
  transform: translateX(0);
  pointer-events: auto;
}
#${HISTORY_POPUP_ID} .dsm-his-item.dsm-selected {
  border-color: #93c5fd;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.14) inset;
}
#${HISTORY_POPUP_ID} .dsm-his-item.dsm-removing {
  opacity: 0;
  transform: translateY(-6px) scale(0.98);
  margin-top: 0;
  margin-bottom: 0;
  padding-top: 0;
  padding-bottom: 0;
  pointer-events: none;
}
#${HISTORY_POPUP_ID} .dsm-his-empty {
  border: 1px dashed #cbd5e1;
  border-radius: 10px;
  padding: 16px 10px;
  text-align: center;
  color: #64748b;
  font-size: 12px;
}
`;
    document.documentElement.appendChild(style);
  }

  function formatTime(ts) {
    try {
      const d = new Date(ts);
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const h = String(d.getHours()).padStart(2, '0');
      const min = String(d.getMinutes()).padStart(2, '0');
      const s = String(d.getSeconds()).padStart(2, '0');
      return `${y}-${m}-${day} ${h}:${min}:${s}`;
    } catch (_) {
      return '';
    }
  }

  function getMountRoot() {
    return document.body || document.documentElement || null;
  }

  function ensureSettingsFab() {
    ensureStyles();
    const root = getMountRoot();
    if (!root) return false;
    let fab = document.getElementById(SETTINGS_FAB_ID);
    if (!fab) {
      fab = document.createElement('button');
      fab.id = SETTINGS_FAB_ID;
      fab.title = '脚本设置';
      fab.textContent = '设置';
      fab.addEventListener('click', showSettingsPopup);
      root.appendChild(fab);
    }
    return true;
  }

  function installSettingsFabKeeper() {
    const revive = () => {
      if (!document.getElementById(SETTINGS_FAB_ID)) {
        ensureSettingsFab();
      }
    };

    const startObserve = () => {
      const root = document.documentElement;
      if (!root) return;
      const ob = new MutationObserver(revive);
      ob.observe(root, { subtree: true, childList: true });
    };

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        revive();
        startObserve();
      }, { once: true });
    } else {
      revive();
      startObserve();
    }

    setInterval(revive, 2000);
  }

  function pushHistory(info) {
    historyRecords.unshift({
      id: `h-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      at: Date.now(),
      info: { ...info }
    });
    if (historyRecords.length > 50) historyRecords.length = 50;
  }

  function closeSettingsPopup(mask) {
    if (!mask || mask.dataset.closing === '1') return;
    mask.dataset.closing = '1';
    mask.classList.remove('dsm-open');
    mask.classList.add('dsm-close');
    setTimeout(() => {
      mask.remove();
    }, 220);
  }

  function showSettingsPopup() {
    ensureStyles();

    const old = document.getElementById(SETTINGS_POPUP_ID);
    if (old) old.remove();

    const mask = document.createElement('div');
    mask.id = SETTINGS_POPUP_ID;

    const box = document.createElement('div');
    box.className = 'dsm-set-box';

    const title = document.createElement('div');
    title.className = 'dsm-set-title';
    title.textContent = '脚本设置';
    box.appendChild(title);

    const rowStrict = document.createElement('div');
    rowStrict.className = 'dsm-set-row';
    rowStrict.innerHTML = `
      <label class="dsm-set-label">
        <input id="dsm-set-strict" type="checkbox" ${strictInterceptEnabled ? 'checked' : ''} />
        严格拦截
      </label>
      <div class="dsm-set-desc">开启后只拦截目标 URL；关闭后按路径宽松匹配（${TARGET_PATH}）。</div>
    `;
    box.appendChild(rowStrict);

    const rowUrl = document.createElement('div');
    rowUrl.className = 'dsm-set-row dsm-set-collapsible';
    rowUrl.innerHTML = `
      <label class="dsm-set-label" for="dsm-set-url">自定义拦截地址</label>
      <div class="dsm-set-input-wrap">
        <input id="dsm-set-url" class="dsm-set-input" type="text" />
        <button id="dsm-set-url-clear" type="button" class="dsm-set-clear-btn">清空</button>
      </div>
      <div class="dsm-set-desc">留空时使用默认地址：${getDefaultInterceptUrl()}</div>
    `;
    box.appendChild(rowUrl);

    const strictCheckbox = rowStrict.querySelector('#dsm-set-strict');
    const inputUrl = rowUrl.querySelector('#dsm-set-url');
    const clearUrlBtn = rowUrl.querySelector('#dsm-set-url-clear');
    inputUrl.value = String(customInterceptUrl || '');
    if (!strictInterceptEnabled) {
      rowUrl.classList.add('is-collapsed');
    }

    const actions = document.createElement('div');
    actions.className = 'dsm-set-actions';

    strictCheckbox.addEventListener('change', () => {
      strictInterceptEnabled = !!strictCheckbox.checked;
      gmSetValueSafe(STORE_STRICT_INTERCEPT, strictInterceptEnabled);
      rowUrl.classList.toggle('is-collapsed', !strictInterceptEnabled);
    });

    inputUrl.addEventListener('input', () => {
      customInterceptUrl = String(inputUrl.value || '').trim();
      gmSetValueSafe(STORE_CUSTOM_INTERCEPT_URL, customInterceptUrl);
    });

    clearUrlBtn.addEventListener('click', () => {
      inputUrl.value = '';
      customInterceptUrl = '';
      gmSetValueSafe(STORE_CUSTOM_INTERCEPT_URL, customInterceptUrl);
      inputUrl.focus();
    });

    const resetBtn = document.createElement('button');
    resetBtn.className = 'dsm-set-btn';
    resetBtn.textContent = '恢复默认地址';
    resetBtn.addEventListener('click', () => {
      inputUrl.value = getDefaultInterceptUrl();
      customInterceptUrl = inputUrl.value;
      gmSetValueSafe(STORE_CUSTOM_INTERCEPT_URL, customInterceptUrl);
    });

    const historyBtn = document.createElement('button');
    historyBtn.className = 'dsm-set-btn';
    historyBtn.textContent = '查看历史记录';
    historyBtn.addEventListener('click', () => {
      closeSettingsPopup(mask);
      showHistoryPopup();
    });

    actions.appendChild(resetBtn);
    actions.appendChild(historyBtn);
    box.appendChild(actions);

    mask.addEventListener('click', (e) => {
      if (e.target === mask) closeSettingsPopup(mask);
    });
    mask.appendChild(box);
    document.documentElement.appendChild(mask);
    requestAnimationFrame(() => {
      mask.classList.add('dsm-open');
    });
  }

  function showHistoryPopup() {
    ensureStyles();

    const old = document.getElementById(HISTORY_POPUP_ID);
    if (old) old.remove();

    const mask = document.createElement('div');
    mask.id = HISTORY_POPUP_ID;

    const box = document.createElement('div');
    box.className = 'dsm-his-box';

    const head = document.createElement('div');
    head.className = 'dsm-his-head';

    const title = document.createElement('div');
    title.className = 'dsm-his-title';
    title.textContent = `历史记录（${historyRecords.length}）`;

    const tools = document.createElement('div');
    tools.className = 'dsm-his-tools';

    const batchToggleBtn = document.createElement('button');
    batchToggleBtn.className = 'dsm-his-btn';
    batchToggleBtn.textContent = '批量管理';

    const clearAllBtn = document.createElement('button');
    clearAllBtn.className = 'dsm-his-btn dsm-his-btn-danger';
    clearAllBtn.textContent = '清空全部';

    const closeBtn = document.createElement('button');
    closeBtn.className = 'dsm-his-btn';
    closeBtn.textContent = '关闭';
    closeBtn.addEventListener('click', () => mask.remove());

    tools.appendChild(batchToggleBtn);
    tools.appendChild(clearAllBtn);
    tools.appendChild(closeBtn);
    head.appendChild(title);
    head.appendChild(tools);
    box.appendChild(head);

    const batchTools = document.createElement('div');
    batchTools.className = 'dsm-his-batch-tools';

    const selectAllBtn = document.createElement('button');
    selectAllBtn.className = 'dsm-his-btn';
    selectAllBtn.textContent = '全选';

    const clearSelBtn = document.createElement('button');
    clearSelBtn.className = 'dsm-his-btn';
    clearSelBtn.textContent = '清空选择';

    const deleteSelBtn = document.createElement('button');
    deleteSelBtn.className = 'dsm-his-btn dsm-his-btn-danger';
    deleteSelBtn.textContent = '删除所选';

    batchTools.appendChild(selectAllBtn);
    batchTools.appendChild(clearSelBtn);
    batchTools.appendChild(deleteSelBtn);
    box.appendChild(batchTools);

    const list = document.createElement('div');
    box.appendChild(list);

    let batchMode = false;
    const selectedIds = new Set();

    const toggleSelect = (id) => {
      if (selectedIds.has(id)) selectedIds.delete(id);
      else selectedIds.add(id);
    };

    const renderList = () => {
      title.textContent = `历史记录（${historyRecords.length}）`;
      list.innerHTML = '';

      if (!historyRecords.length) {
        const empty = document.createElement('div');
        empty.className = 'dsm-his-empty';
        empty.textContent = '暂无历史记录';
        list.appendChild(empty);
        return;
      }

      historyRecords.forEach((item) => {
        const el = document.createElement('div');
        el.className = `dsm-his-item${selectedIds.has(item.id) ? ' dsm-selected' : ''}`;

        const top = document.createElement('div');
        top.className = 'dsm-his-top';

        const left = document.createElement('div');
        left.className = 'dsm-his-top-left';

        const selectBtn = document.createElement('input');
        selectBtn.type = 'checkbox';
        selectBtn.className = 'dsm-his-item-select';
        selectBtn.checked = selectedIds.has(item.id);
        selectBtn.addEventListener('change', (e) => {
          e.stopPropagation();
          toggleSelect(item.id);
          renderList();
        });

        const host = document.createElement('div');
        host.className = 'dsm-his-host';
        host.textContent = `${item.info.username || '-'} @ ${item.info.host || '-'}`;

        left.appendChild(selectBtn);
        left.appendChild(host);

        const time = document.createElement('div');
        time.className = 'dsm-his-time';
        time.textContent = formatTime(item.at);

        top.appendChild(left);
        top.appendChild(time);

        const meta = document.createElement('div');
        meta.className = 'dsm-his-meta';
        meta.textContent = `${item.info.protocol || '-'} / 端口 ${item.info.port || '22'}`;

        const actions = document.createElement('div');
        actions.className = 'dsm-his-item-actions';

        const openBtn = document.createElement('button');
        openBtn.className = 'dsm-his-btn';
        openBtn.textContent = '查看详情';
        openBtn.addEventListener('click', () => showPopup(item.info));

        const copyBtn = document.createElement('button');
        copyBtn.className = 'dsm-his-btn';
        copyBtn.textContent = '复制新版 SSH';
        copyBtn.addEventListener('click', () => {
          safeCopy(item.info.sshCmdModern || item.info.sshCmd || '');
          copyBtn.textContent = '已复制';
          setTimeout(() => {
            copyBtn.textContent = '复制新版 SSH';
          }, 1200);
        });

        actions.appendChild(openBtn);
        actions.appendChild(copyBtn);

        el.appendChild(top);
        el.appendChild(meta);
        el.appendChild(actions);

        if (batchMode) {
          el.addEventListener('click', (e) => {
            const t = e.target;
            if (t && (t.closest('button') || t.closest('a') || t.closest('input'))) return;
            toggleSelect(item.id);
            renderList();
          });
        }

        list.appendChild(el);
      });
    };

    batchToggleBtn.addEventListener('click', () => {
      batchMode = !batchMode;
      if (!batchMode) selectedIds.clear();
      mask.classList.toggle('dsm-batch-mode', batchMode);
      batchToggleBtn.textContent = batchMode ? '退出批量' : '批量管理';
      renderList();
    });

    selectAllBtn.addEventListener('click', () => {
      selectedIds.clear();
      historyRecords.forEach((item) => selectedIds.add(item.id));
      renderList();
    });

    clearSelBtn.addEventListener('click', () => {
      selectedIds.clear();
      renderList();
    });

    deleteSelBtn.addEventListener('click', () => {
      if (!selectedIds.size) return;
      const idsToDelete = new Set(selectedIds);
      const removingItems = Array.from(list.querySelectorAll('.dsm-his-item.dsm-selected'));

      const applyDelete = () => {
        const remain = historyRecords.filter((item) => !idsToDelete.has(item.id));
        historyRecords.length = 0;
        remain.forEach((item) => historyRecords.push(item));
        selectedIds.clear();
        renderList();
      };

      if (!removingItems.length) {
        applyDelete();
        return;
      }

      deleteSelBtn.disabled = true;

      removingItems.forEach((el) => {
        el.style.maxHeight = `${el.offsetHeight}px`;
      });

      requestAnimationFrame(() => {
        removingItems.forEach((el) => {
          void el.offsetHeight;
          el.classList.add('dsm-removing');
          el.style.maxHeight = '0px';
        });
      });

      setTimeout(() => {
        applyDelete();
        deleteSelBtn.disabled = false;
      }, 280);
    });

    clearAllBtn.addEventListener('click', () => {
      if (!historyRecords.length) return;

      const removingItems = Array.from(list.querySelectorAll('.dsm-his-item'));
      const applyClearAll = () => {
        historyRecords.length = 0;
        selectedIds.clear();
        renderList();
      };

      if (!removingItems.length) {
        applyClearAll();
        return;
      }

      clearAllBtn.disabled = true;
      deleteSelBtn.disabled = true;

      removingItems.forEach((el) => {
        el.style.maxHeight = `${el.offsetHeight}px`;
      });

      requestAnimationFrame(() => {
        removingItems.forEach((el) => {
          void el.offsetHeight;
          el.classList.add('dsm-removing');
          el.style.maxHeight = '0px';
        });
      });

      setTimeout(() => {
        applyClearAll();
        clearAllBtn.disabled = false;
        deleteSelBtn.disabled = false;
      }, 280);
    });

    renderList();

    mask.addEventListener('click', (e) => {
      if (e.target === mask) mask.remove();
    });
    mask.appendChild(box);
    document.documentElement.appendChild(mask);
  }

  function createButton(label, value) {
    const btn = document.createElement('button');
    btn.textContent = label;
    btn.className = 'dsm-copy';
    btn.addEventListener('click', () => {
      safeCopy(value);
      btn.textContent = '已复制';
      setTimeout(() => {
        btn.textContent = label;
      }, 1200);
    });
    return btn;
  }

  function addRow(container, title, value, options) {
    const opts = options || {};
    const copyText = Object.prototype.hasOwnProperty.call(opts, 'copyText') ? opts.copyText : '';
    const isSecret = !!opts.secret;
    const tipText = String(opts.tipText || '');
    const preserveLineBreaks = !!opts.preserveLineBreaks;
    const isCollapsible = !!opts.collapsible;
    const row = document.createElement('div');
    row.className = 'dsm-row';

    const k = document.createElement('div');
    k.className = 'dsm-key';
    k.textContent = title;

    const v = document.createElement('div');
    v.className = 'dsm-val';
    const rawValue = value || '';
    v.textContent = isSecret ? '••••••••' : rawValue;
    if (preserveLineBreaks && !isCollapsible) {
      v.style.whiteSpace = 'pre-wrap';
      v.style.fontSize = '12px';
    }

    const action = document.createElement('div');
    action.className = 'dsm-action';

    row.appendChild(k);
    row.appendChild(v);

    if (isSecret) {
      const toggleBtn = document.createElement('button');
      toggleBtn.textContent = '显示';
      toggleBtn.className = 'dsm-copy';
      let visible = false;
      toggleBtn.addEventListener('click', () => {
        visible = !visible;
        v.textContent = visible ? rawValue : '••••••••';
        toggleBtn.textContent = visible ? '隐藏' : '显示';
      });
      action.appendChild(toggleBtn);
    }

    if (isCollapsible) {
      let expanded = false;
      const lines = String(rawValue || '').split('\n').filter(Boolean).length || 1;

      const preview = document.createElement('div');
      preview.className = 'dsm-collapsible-preview';
      preview.textContent = `已折叠（${lines} 行），点击“展开”查看`;

      const content = document.createElement('div');
      content.className = 'dsm-collapsible-content';
      content.textContent = rawValue;
      content.style.whiteSpace = preserveLineBreaks ? 'pre-wrap' : 'normal';
      if (preserveLineBreaks) content.style.fontSize = '12px';

      v.textContent = '';
      v.style.whiteSpace = 'normal';
      v.appendChild(preview);
      v.appendChild(content);

      const collapseBtn = document.createElement('button');
      collapseBtn.textContent = '展开';
      collapseBtn.className = 'dsm-copy';
      collapseBtn.addEventListener('click', () => {
        expanded = !expanded;
        if (expanded) {
          preview.style.display = 'none';
          content.classList.add('is-expanded');
          collapseBtn.textContent = '收起';
        } else {
          content.classList.remove('is-expanded');
          preview.style.display = '';
          collapseBtn.textContent = '展开';
        }
      });
      action.appendChild(collapseBtn);
    }

    if (tipText) {
      const tip = document.createElement('span');
      tip.className = 'dsm-info-icon';
      tip.textContent = 'i';
      tip.title = tipText;
      action.appendChild(tip);
    }
    if (copyText) {
      action.appendChild(createButton('复制', copyText));
    }
    row.appendChild(action);

    container.appendChild(row);
  }

  function showPopup(info) {
    ensureStyles();

    const old = document.getElementById('dasusm-extractor-popup');
    if (old) old.remove();

    const mask = document.createElement('div');
    mask.id = 'dasusm-extractor-popup';

    const box = document.createElement('div');
    box.className = 'dsm-box';

    const head = document.createElement('div');
    head.className = 'dsm-head';

    const titleWrap = document.createElement('div');
    titleWrap.className = 'dsm-title-wrap';

    const title = document.createElement('div');
    title.className = 'dsm-title';
    title.textContent = `DASUSM 提取结果 v${SCRIPT_VER}`;

    const close = document.createElement('button');
    close.textContent = '关闭';
    close.className = 'dsm-close';
    close.addEventListener('click', () => mask.remove());

    titleWrap.appendChild(title);
    head.appendChild(titleWrap);
    head.appendChild(close);
    box.appendChild(head);

    addRow(box, '用户名', info.username, { copyText: info.username });
    addRow(box, '临时密码', info.ssoToken, { copyText: info.ssoToken, secret: true });
    addRow(box, '主机', info.host, { copyText: info.host });
    addRow(box, '端口', info.port, { copyText: info.port });
    addRow(box, '协议', info.protocol, { copyText: info.protocol });
    addRow(box, 'SSH 命令', info.sshCmd, { copyText: info.sshCmd });
    addRow(box, '新版 SSH 命令', info.sshCmdModern, {
      copyText: info.sshCmdModern,
      tipText: '如果连接报错，那么就用这个。'
    });
    addRow(box, 'SSH 配置文件', info.sshConfigEntry, {
      copyText: info.sshConfigEntry,
      preserveLineBreaks: true,
      collapsible: true
    });

    const mainActions = document.createElement('div');
    mainActions.className = 'dsm-main-actions';

    const copyMain = document.createElement('button');
    copyMain.className = 'dsm-main-copy';
    copyMain.textContent = '复制新版 SSH 命令';
    copyMain.addEventListener('click', () => {
      safeCopy(info.sshCmdModern || info.sshCmd || '');
      copyMain.textContent = '已复制';
      setTimeout(() => {
        copyMain.textContent = '复制新版 SSH 命令';
      }, 1200);
    });

    const copySftp = document.createElement('button');
    copySftp.className = 'dsm-main-copy dsm-main-copy-sftp';
    copySftp.textContent = '复制 SFTP 命令';
    copySftp.addEventListener('click', () => {
      safeCopy(info.sftpCmdModern || info.sftpCmd || '');
      copySftp.textContent = '已复制';
      setTimeout(() => {
        copySftp.textContent = '复制 SFTP 命令';
      }, 1200);
    });

    mainActions.appendChild(copyMain);
    mainActions.appendChild(copySftp);
    box.appendChild(mainActions);

    const hint = document.createElement('div');
    hint.className = 'dsm-hint';
    hint.textContent = '提示：点击每行“复制”或直接使用一键复制。';
    box.appendChild(hint);

    mask.addEventListener('click', (e) => {
      if (e.target === mask) mask.remove();
    });

    mask.appendChild(box);
    document.documentElement.appendChild(mask);
  }

  function processResponseJson(json) {
    if (!json || typeof json !== 'object') return;
    if (typeof json.url !== 'string' || !json.url.toLowerCase().startsWith('dasusm://')) return;

    const decoded = parseDasusmUrl(json.url);
    const node = pickCoreNode(decoded);
    if (!node) return;

    const username = String(node.Username || '').trim();
    const ssoToken = String(node.SSOToken || '').trim();
    const host = String(node.IPv4 || node.AssetIPv4 || '').trim();
    const port = String(node.Port || node.AssetPort || '').trim();
    const protocol = String(node.Protocol || '').trim();

    if (!username || !host) return;

    const sshCmd = `ssh -p ${port || '22'} ${username}@${host}`;
    const sshCmdModern = `${sshCmd} -o PubkeyAuthentication=no -o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o MACs=+hmac-sha1`;
    const sftpCmd = buildSftpCmd(host, port, username);
    const sftpCmdModern = buildSftpCmdModern(host, port, username);
    const sshConfigEntry = buildSshConfigEntry(host, port, username);

    showPopup({
      username,
      ssoToken,
      host,
      port,
      protocol,
      sshCmd,
      sshCmdModern,
      sftpCmd,
      sftpCmdModern,
      sshConfigEntry
    });

    pushHistory({
      username,
      ssoToken,
      host,
      port,
      protocol,
      sshCmd,
      sshCmdModern,
      sftpCmd,
      sftpCmdModern,
      sshConfigEntry
    });
  }

  function shouldHandleUrl(url) {
    if (typeof url !== 'string') return false;
    if (strictInterceptEnabled) {
      return normalizeUrl(url) === normalizeUrl(getEffectiveInterceptUrl());
    }
    try {
      const u = new URL(url, location.href);
      return u.pathname.endsWith(TARGET_PATH);
    } catch (_) {
      return url.includes(TARGET_PATH);
    }
  }

  function installFetchHook() {
    const rawFetch = window.fetch;
    if (typeof rawFetch !== 'function') return;

    window.fetch = async function (...args) {
      const res = await rawFetch.apply(this, args);

      try {
        const input = args[0];
        const url = typeof input === 'string' ? input : (input && input.url);
        if (shouldHandleUrl(url)) {
          const cloned = res.clone();
          const ct = (cloned.headers.get('content-type') || '').toLowerCase();
          if (!ct || ct.includes('application/json') || ct.includes('text/plain')) {
            const text = await cloned.text();
            const json = safeJsonParse(text);
            processResponseJson(json);
          }
        }
      } catch (_) {}

      return res;
    };
  }

  function installXhrHook() {
    const rawOpen = XMLHttpRequest.prototype.open;
    const rawSend = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function (method, url, ...rest) {
      this.__dasusm_url = url;
      return rawOpen.call(this, method, url, ...rest);
    };

    XMLHttpRequest.prototype.send = function (...args) {
      this.addEventListener('readystatechange', function () {
        if (this.readyState !== 4) return;

        try {
          if (!shouldHandleUrl(this.__dasusm_url)) return;
          const text = this.responseType === '' || this.responseType === 'text' ? this.responseText : '';
          const json = safeJsonParse(text);
          processResponseJson(json);
        } catch (_) {}
      });

      return rawSend.apply(this, args);
    };
  }

  function shouldReplaceSsoNotice(text) {
    const t = String(text || '');
    if (!t) return false;
    return (
      (t.includes('没有安装单点登录器') || t.includes('未安装单点登录器')) &&
      (t.includes('单点登录插件被禁用') || t.includes('单点登录插件'))
    );
  }

  function isElementHidden(el) {
    if (!el || el.nodeType !== 1) return false;
    try {
      const cs = window.getComputedStyle(el);
      return cs.display === 'none' || cs.visibility === 'hidden';
    } catch (_) {
      return el.style && (el.style.display === 'none' || el.style.visibility === 'hidden');
    }
  }

  function markSsoNoticeInternalUpdating(el) {
    if (!el || !el.dataset) return;
    el.dataset.dsmInternalUpdating = '1';
    setTimeout(() => {
      if (el && el.dataset) delete el.dataset.dsmInternalUpdating;
    }, 0);
  }

  function isSsoNoticeInternalUpdating(el) {
    return !!(el && el.dataset && el.dataset.dsmInternalUpdating === '1');
  }

  function getSsoWarningBannerId(el) {
    const baseId = (el && el.id) ? el.id : SSO_MSG_ID;
    return `${baseId}-dsm-proprietary-warning`;
  }

  function isWindowsSystem() {
    try {
      const uaDataPlatform = navigator.userAgentData && navigator.userAgentData.platform
        ? String(navigator.userAgentData.platform)
        : '';
      const platform = navigator.platform ? String(navigator.platform) : '';
      const ua = navigator.userAgent ? String(navigator.userAgent) : '';
      const s = `${uaDataPlatform} ${platform} ${ua}`.toLowerCase();
      return s.includes('win');
    } catch (_) {
      return false;
    }
  }

  function fillProprietaryWarningNotice(el) {
    if (!el) return;
    const toolsUrl = `${location.origin}/index.php/tools`;
    const uninstallBtnHtml = isWindowsSystem()
      ? ` <button type="button" data-dsm-uninstall-btn="1" style="margin-left:8px;border:1px solid #ef4444;background:#b91c1c;color:#fff;border-radius:6px;padding:3px 8px;cursor:pointer;">卸载这两个软件</button>`
      : '';
    el.innerHTML =
      `<strong style="color:#b91c1c;">⚠ 安全警告：</strong>` +
      `检测到你已安装“单点登陆器”（USMSSO）和 “USBKEY控件 (IE)”（USMWebControl）等专有软件。专有软件对用户不透明、不可审计、不可控，` +
      `你无法确认它是否在监视、限制或操纵你的系统行为。` +
      ` 这两个软件来自当前站点的<a href="${toolsUrl}" target="_blank" rel="noopener noreferrer">工具下载页</a>。` +
      ` <a href="https://www.gnu.org/proprietary/proprietary.html" target="_blank" rel="noopener noreferrer">了解更多</a>` +
      uninstallBtnHtml;
    el.style.color = '#7f1d1d';
    el.style.background = '#fff1f2';
    el.style.border = '1px solid #fda4af';
    el.style.borderRadius = '8px';
    el.style.padding = '8px 10px';
    el.style.display = 'block';
    el.style.visibility = 'visible';
    el.style.opacity = '1';
  }

  function bindUninstallButton(el) {
    if (!el || !el.querySelector) return;
    const btn = el.querySelector('button[data-dsm-uninstall-btn="1"]');
    if (!btn) return;
    if (btn.dataset && btn.dataset.dsmBound === '1') return;
    if (btn.dataset) btn.dataset.dsmBound = '1';
    btn.addEventListener('click', () => {
      alert(
        '请在卸载列表中找到并卸载以下软件：\n' +
        '1. 运维审计系统 USBKEY组件（发布者：USM Team）\n' +
        '2. 运维审计系统 单点登录组件 2.0（发布者：USM Team）'
      );

      const target = 'ms-settings:appsfeatures';
      let opened = false;
      try {
        const w = window.open(target, '_blank');
        opened = !!w;
      } catch (_) {}
      if (!opened) {
        try {
          window.location.href = target;
          opened = true;
        } catch (_) {}
      }
      if (!opened) {
        alert('若未自动打开，请按 Win + R，输入 appwiz.cpl 并回车，进入控制面板卸载程序页面。');
      }
    });
  }

  function removeExtraWarningNotice(el) {
    if (!el || !el.parentNode) return;
    const old = document.getElementById(getSsoWarningBannerId(el));
    if (old && old.parentNode) old.parentNode.removeChild(old);
  }

  function ensureExtraWarningNoticeAbove(el) {
    if (!el || !el.parentNode) return;
    const warningId = getSsoWarningBannerId(el);
    let warningEl = document.getElementById(warningId);
    if (!warningEl) {
      warningEl = document.createElement('div');
      warningEl.id = warningId;
      warningEl.className = el.className || 'notice danger';
      markSsoNoticeInternalUpdating(warningEl);
      el.parentNode.insertBefore(warningEl, el);
    }
    markSsoNoticeInternalUpdating(warningEl);
    fillProprietaryWarningNotice(warningEl);
    bindUninstallButton(warningEl);
  }

  function replaceSsoNoticeElement(el) {
    if (!el || el.nodeType !== 1) return false;
    if (!pageFullyLoaded) return false;
    if (isSsoNoticeInternalUpdating(el)) return false;
    const wasManaged = !!(el.dataset && el.dataset.dsmReplaced === '1');
    if (wasManaged && el.dataset && el.dataset.dsmFinalRendered === '1') return false;
    if (!wasManaged && !shouldReplaceSsoNotice(el.textContent || '')) return false;

    if (ssoWarningDecision === null) {
      ssoWarningDecision = isElementHidden(el);
    }
    const shouldShowProprietaryWarning = !!ssoWarningDecision;

    markSsoNoticeInternalUpdating(el);
    let replacedInnerHtml = '';
    replacedInnerHtml += `<div class="dsm-sso-notice-wrap" style="display:flex;flex-direction:column;gap:8px;">`;
    if (shouldShowProprietaryWarning) {
      const toolsUrl = `${location.origin}/index.php/tools`;
      replacedInnerHtml += `<div style="color:#7f1d1d;background:#fff1f2;border:1px solid #fda4af;border-radius:8px;padding:8px 10px;">`;
      replacedInnerHtml += `<strong style="color:#b91c1c;">⚠ 安全警告：</strong>`;
      replacedInnerHtml += ` 检测到你已安装“单点登陆器”（USMSSO）和“USBKEY控件 (IE)”（USMWebControl）等专有软件。`;
      replacedInnerHtml += ` 这两个软件来自当前站点的<a href="${toolsUrl}" target="_blank" rel="noopener noreferrer">工具下载页</a>。`;
      replacedInnerHtml += ` <a href="https://www.gnu.org/proprietary/proprietary.html" target="_blank" rel="noopener noreferrer">了解更多</a>`;
      if (isWindowsSystem()) {
        replacedInnerHtml += ` <button type="button" data-dsm-uninstall-btn="1" style="margin-left:8px;border:1px solid #ef4444;background:#b91c1c;color:#fff;border-radius:6px;padding:3px 8px;cursor:pointer;">卸载这两个软件</button>`;
      }
      replacedInnerHtml += `</div>`;
    }
    replacedInnerHtml += `<div style="color:#14532d;background:#f0fdf4;border:1px solid #86efac;border-radius:8px;padding:8px 10px;">`;
    replacedInnerHtml += `<strong style="color:#15803d;">✔</strong> `;
    replacedInnerHtml += `已连接油猴脚本（${SCRIPT_NAME} v${SCRIPT_VER}），可直接继续使用堡垒机登录流程。`;
    replacedInnerHtml += `</div>`;
    replacedInnerHtml += `</div>`;
    el.innerHTML = replacedInnerHtml;
    el.style.color = '';
    el.style.background = 'transparent';
    el.style.border = '0';
    bindUninstallButton(el);

    el.dataset.dsmReplaced = '1';
    el.dataset.dsmFinalRendered = '1';
    el.style.display = 'block';
    el.style.visibility = 'visible';
    el.style.opacity = '1';
    el.style.borderRadius = '8px';
    el.style.padding = '8px 10px';
    return true;
  }

  function scanAndReplaceSsoNotice(root) {
    const scope = root && root.querySelectorAll ? root : document;
    const exact = document.getElementById(SSO_MSG_ID);
    if (exact) replaceSsoNoticeElement(exact);
    const nodes = scope.querySelectorAll ? scope.querySelectorAll('.notice.danger, #ssomsg') : [];
    nodes.forEach((el) => replaceSsoNoticeElement(el));
  }

  function installSsoNoticeInterceptor() {
    const run = () => {
      if (ssoWarningDecision === null) {
        const exact = document.getElementById(SSO_MSG_ID);
        if (exact && shouldReplaceSsoNotice(exact.textContent || '')) {
          ssoWarningDecision = isElementHidden(exact);
        }
      }
      scanAndReplaceSsoNotice(document);
    };

    if (document.readyState === 'complete') {
      pageFullyLoaded = true;
      run();
    } else {
      window.addEventListener('load', () => {
        pageFullyLoaded = true;
        run();
      }, { once: true });
    }

    const ob = new MutationObserver((mutations) => {
      if (!pageFullyLoaded) return;
      for (const m of mutations) {
        if (m.type === 'childList') {
          m.addedNodes.forEach((node) => {
            if (!node || node.nodeType !== 1) return;
            if (node.id === SSO_MSG_ID) {
              replaceSsoNoticeElement(node);
              return;
            }
            scanAndReplaceSsoNotice(node);
          });
        } else if (m.type === 'characterData') {
          const parent = m.target && m.target.parentElement;
          if (parent) replaceSsoNoticeElement(parent);
        } else if (m.type === 'attributes') {
          if (isSsoNoticeInternalUpdating(m.target)) continue;
          replaceSsoNoticeElement(m.target);
        }
      }
    });

    ob.observe(document.documentElement, {
      subtree: true,
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ['style', 'class']
    });
  }

  installFetchHook();
  installXhrHook();
  installSsoNoticeInterceptor();
  ensureSettingsFab();
  installSettingsFabKeeper();
})();

```