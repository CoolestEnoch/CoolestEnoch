---
title: 万物皆可沙箱化！BubbleWrap简单上手
category: Linux
date: 2026-01-01 00:00:00
updated: 2026-01-01 00:00:00
index_img: https://no_image
---


# TL;DR
最近存在一个问题，运行一些非自由软件时，它们老喜欢搞事情，比如在后台放一个云同步服务，你把软件关了那个云同步还不会一起关；亦或会闲得没事往你电脑里拉屎，不仅占空间，而且还多处一堆奇奇怪怪的文件夹。


这个时候，就要请出我们的老朋友，`bwrap`了！它可以仅授权某些文件夹的访问，也可以仅授权某些文件夹的只读访问，也可以更改应用看到的文件夹结构，直观体验就像安卓上的[存储空间隔离 by Rikka](https://sr.rikka.app)一样。


[这是项目官方的仓库](https://github.com/containers/bubblewrap)。


# 安装
安装起来十分简单啊，直接一行命令就行了：
``` shell
sudo pacman -S bubblewrap
```


# 使用
直接保存这个脚本，然后在它后面接要运行的应用程序名就行，已经做了英特尔和nVidia双显卡自动检测兼容；也可以直接source这个脚本，然后直接在命令行里`bwrap_run xxx`就行，不过为了安全，这样会跳过`bind_maps`那块。
举个例子：
``` shell
# 从本地脚本运行
./bwrap_run.sh bash
# source后可以直接运行，但会跳过 bind_maps
bwrap_run bash
```
这样会打开一个沙箱内的bash，然后在沙箱里再运行不放心的软件就行了，亦或运行wine！这样就不用担心wine闲得没事把你每个磁盘都挂上然后你运行的某些exe往里面拉屎了！


***当你在沙箱的shell里运行`exit`后，整个沙箱内的所有子进程都会被一起结束！十分的纯净，不留痕！软件运行过程中拉的屎都存在内存里，当沙箱结束后会一并从内存中删除，全程0接触物理磁盘！***


## 对于Coding Agent安全：
目标是，除了当前目录、部分允许访问的目录、`/dev/nvidia*`外，其他都是只读，不许读写。如果看都不给看，可能会引起一些小问题。适合用这个版本：
``` shell
#!/usr/bin/env bash

bwrap_run() {
	(
		set -euo pipefail

		# =================== 配置 ===================
		local WORK_DIR="$(pwd)"
		local USER_ID="$(id -u)"
		local GROUP_ID="$(id -g)"

		# 直通只读的文件夹白名单
		local ro_dirs=(
			# 系统配置
			"$HOME/.local/share/fonts"
		)

		# 直通读写的文件夹白名单
		local allowed_dirs=(
			# 直通的目录
			"/home/enoch/Documents/bwrap_transfer"
			"/home/enoch/Documents/GlobalFileTransfer/WIP"
			"$HOME/Documents/WIP"
			# Proton
			"$HOME/.local/share/Steam"
			# UV
			"$HOME/.cache/uv"
			"$HOME/.local/share/uv"
			"$HOME/.local/bin/uv" # 官方脚本的安装目录
			# WPS
			"$HOME/.config/Kingsoft"
			"/opt/kingsoft"
			# HMCL
			"$HOME/.local/share/hmcl"
			# Wine Prefix NCM
			"$HOME/Documents/wine_exe"
		)

		# 跨磁盘允许读写用这个加白
		local bind_maps_force=(
		)
		# 跨磁盘允许读写用这个加白, 但只允许从脚本运行时加白
		local bind_maps=(
			"/run/media/$USER/Data/哈哈哈/uncompress::gamesuncompress_bwrap"
			"/run/media/$USER/Data_Samsung/Env/哈哈哈/uncompress::gamesuncompress_870_bwrap"
			"/run/media/$USER/Software_Master/games::gamesuncompress_980_bwrap"
		)
		local bind_maps_created=()
		if [[ ! -v bwrap_run_from_script ]]; then
			bind_maps=()
			echo "警告: 从source的函数运行, 跳过挂载bind_maps"
		fi
		# 文件夹映射
		local bind_maps_absloute=(
			"$HOME/Documents/bwrap_home::$HOME"
		)

		# 环境变量
		local env_vars=(
			"LANG=zh_CN.UTF-8"
			"LC_ALL=zh_CN.UTF-8"
			# NVIDIA（有则生效）
			"__GL_THREADED_OPTIMIZATIONS=1"
		)

		# =================== 构建 bwrap 参数 ===================
		local bargs=(
			--unshare-pid		   # 创建独立 PID namespace
			--die-with-parent	   # 父进程退出时 bwrap 自动杀掉
			--setenv HOME "$HOME"
			--setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
			--chdir "$WORK_DIR"
			--tmpfs /tmp	  # 给 bwrap 内程序干净 tmpfs
			--bind /dev/shm /dev/shm   # 对 MIT-SHM 或 X11 必须的共享内存
		)

		echo "===== Device Checking ====="
		# =================== GPU 类型检测 ===================
		detect_gpu() {
			if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
				printf '%s' "nvidia"
				return
			fi
			if ls /dev/nvidia* >/dev/null 2>&1; then
				printf '%s' "nvidia"
				return
			fi
			for card in /sys/class/drm/card*; do
				local vendor_file="$card/device/vendor"
				[ -r "$vendor_file" ] || continue
				local vendor_hex="$(tr -d ' \n' <"$vendor_file")"
				case "$vendor_hex" in
					*8086*) printf 'intel'; return ;;
					*10de*) printf 'nvidia'; return ;;
					*1002*) printf 'intel'; return ;;
				esac
			done
			printf 'unknown'
		}
		local GPU_TYPE="$(detect_gpu || true)"
		echo "检测到 GPU 类型: $GPU_TYPE"
		# =================== GPU 绑定 ===================
		case "$GPU_TYPE" in
			nvidia)
				echo "绑定 NVIDIA 设备节点"
				for ndev in /dev/nvidia*; do
					[ -e "$ndev" ] && bargs+=( --dev-bind "$ndev" "$ndev" )
				done
				[ -d /dev/dri ] && bargs+=( --dev-bind /dev/dri /dev/dri )
			;;
			intel|unknown)
				[ -d /dev/dri ] && bargs+=( --dev-bind /dev/dri /dev/dri )
			;;
		esac

		# =================== XDG_RUNTIME_DIR / Wayland ===================
		local XDG_RUNTIME_DIR="/run/user/$USER_ID"
		local WAYLAND_SOCKET=""
		if [ -d "$XDG_RUNTIME_DIR" ]; then
			for s in "$XDG_RUNTIME_DIR"/wayland-*; do
				[ -S "$s" ] || continue
				local WAYLAND_SOCKET="$s"
				break
			done
		fi
		[ -n "$WAYLAND_SOCKET" ] && echo "Wayland socket: $WAYLAND_SOCKET"
		[ -n "$WAYLAND_SOCKET" ] && bargs+=( --setenv WAYLAND_DISPLAY "$(basename "$WAYLAND_SOCKET")" )

		# =================== 系统库绑定 ===================
		for d in /usr /bin /sbin /etc ; do # /opt
			[ -d "$d" ] && bargs+=( --ro-bind "$d" "$d" )
		done
		[ -d /usr/lib ] && bargs+=( --ro-bind /usr/lib /usr/lib )
		[ -d /usr/lib32 ] && bargs+=( --ro-bind /usr/lib32 /usr/lib32 )
		[ -d /usr/lib32 ] && bargs+=( --ro-bind /usr/lib32 /lib32 )
		[ -d /lib ] && bargs+=( --ro-bind /lib /lib )
		[ -d /lib64 ] && bargs+=( --ro-bind /lib64 /lib64 )
		bargs+=( --proc /proc )
		bargs+=( --ro-bind /sys /sys )
		[ -d /usr/share/fonts ] && bargs+=( --ro-bind /usr/share/fonts /usr/share/fonts )
		# [ -f /etc/resolv.conf ] && bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
		# DNS: Arch 常见是普通文件；Ubuntu 20.04 常见是 /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
		if [ -L /etc/resolv.conf ]; then
			# 只把 systemd-resolved 相关的那部分 /run 带进来，避免整个 /run 都暴露
			if [ -d /run/systemd/resolve ]; then
				bargs+=( --tmpfs /run )
				bargs+=( --ro-bind /run/systemd/resolve /run/systemd/resolve )
			else
				# 极端情况：是链接但宿主机没这个目录，就退回直接 bind（可能仍会失败，但至少有兜底）
				bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
			fi
		else
			[ -f /etc/resolv.conf ] && bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
		fi

		# ============= 实验室GPU服务器适配 =============
		local HOST_WHITELIST=(
			"ubuntu"
			"y"
			"5024080"
		)
		local cur_host="$(hostname -s 2>/dev/null || hostname)"
		for h in "${HOST_WHITELIST[@]}"; do
			if [[ "$cur_host" == "$h" ]]; then
				ro_dirs+=(
					"$HOME/.oh-my-bash"
					"$HOME/.bashrc"
					"$HOME/.profile"
				)
				env_vars+=(
					"FROM_BWRAP=1"
				)
				allowed_dirs+=(
					# 服务器上的
					"$HOME/bwrap_files/transfer"
					"$HOME/tmp"
				)
				# 删除个人电脑上的/home绑定设置，改成服务器专用的
				for i in "${!bind_maps_absloute[@]}"; do
					if [[ "${bind_maps_absloute[i]}" == *"$HOME/Documents/bwrap_home"* ]]; then
						unset 'bind_maps_absloute[i]'
						bind_maps_absloute=("${bind_maps_absloute[@]}")   # 可选：重建索引
						break			   # 只删第一个；要删全部就去掉 break
					fi
				done
				bind_maps_absloute+=("$HOME/bwrap_files/home::$HOME")

				break
			fi
		done

		# =================== /dev & /dev/shm & runtime ===================
		[ -d /dev ] && bargs+=( --dev-bind /dev /dev )
		[ -d /dev/shm ] && bargs+=( --bind /dev/shm /dev/shm )
		[ -d "$XDG_RUNTIME_DIR" ] && bargs+=( --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" )


		# =================== 用户自定义目录绑定 ===================

		echo "脚本目录: $WORK_DIR"
		echo "用户 HOME: $HOME"
		echo "UID:GID: $USER_ID:$GROUP_ID"

		echo "===== Binding Checking ====="
		echo "ro_dirs:"
		for d in "${ro_dirs[@]}"; do echo "  - $d"; done
		echo "allowed_dirs:"
		for d in "${allowed_dirs[@]}"; do echo "  - $d"; done
		echo "bind_maps:"
		for m in "${bind_maps[@]}"; do echo "  - $m"; done
		echo "bind_maps_force:"
		for m in "${bind_maps_force[@]}"; do echo "  - $m"; done
		echo "bind_maps_absloute:"
		for m in "${bind_maps_absloute[@]}"; do echo "  - $m"; done
		echo "===== Actual Binding ====="
		# =================== 根目录绑定 ===================

		echo "actual bind_maps_absloute:"
		for m in "${bind_maps_absloute[@]}"; do
			host="${m%%::*}"
			target="${m##*::}"
			[ ! -d "$host" ] && echo "$host" && continue
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done
		if [[ "$WORK_DIR" == "$HOME" ]]; then
			echo "警告: WORK_DIR 目录与用户主目录相同! 本次未授权访问主目录"
		else
			bargs+=( --bind "$WORK_DIR" "$WORK_DIR" )
		fi

		# =================== ro_dirs ===================
		for d in "${ro_dirs[@]}"; do
			[ -e "$d" ] && bargs+=( --ro-bind "$d" "$d" )
		done

		# =================== allowed_dirs ===================
		for d in "${allowed_dirs[@]}"; do
			[ -e "$d" ] && bargs+=( --bind "$d" "$d" )
		done

		# =================== 注入环境变量 ===================
		for kv in "${env_vars[@]}"; do
			key="${kv%%=*}"
			val="${kv#*=}"
			bargs+=( --setenv "$key" "$val" )
		done

		# =================== bind_maps ===================
		echo "actual bind_maps:"
		for m in "${bind_maps[@]}"; do
			host="${m%%::*}"
			rel="${m##*::}"
			target="$WORK_DIR/$rel"
			[ ! -d "$host" ] && continue
			[ ! -d "$target" ] && mkdir -p "$target" && bind_maps_created+=("$target")
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done
		echo "actual bind_maps_force:"
		for m in "${bind_maps_force[@]}"; do
			host="${m%%::*}"
			rel="${m##*::}"
			target="$WORK_DIR/$rel"
			[ ! -d "$host" ] && continue
			[ ! -d "$target" ] && mkdir -p "$target" && bind_maps_created+=("$target")
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done

		echo "===== Cleanup Pending: ====="
		echo "bind_maps_created:"
		for m in "${bind_maps_created[@]}"; do echo "  - $m"; done


		# =================== PATH ===================
		bargs+=( --setenv PATH "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH" )

		# 如果要source的话，这段是需要加上的
		# 1) 注入一个安全的、简洁的 PS1 / 清理会搞事的 prompt 变量
		bargs+=( --setenv PS1 '<sandbox>\u@\h:\w\\$ ' )
		bargs+=( --setenv PROMPT_COMMAND '' )
		bargs+=( --setenv RPROMPT '' )
		bargs+=( --setenv VSCODE_INJECTION '' )  # 视具体环境可选
		# 如果你还有别的在 host 导出的 prompt 变量（比如 ZSH_THEME），也可以在这里清空：
		bargs+=( --setenv ZLE_RPROMPT '' )
		# 2) 决定要执行的命令：若用户传 "bash"，用干净交互 bash；否则执行传入命令
		if [ "${#@}" -ge 1 ] && [ "$1" = "bash" ]; then
			shift
			local CMD=( bash -i "$@" )
		else
			# preserve original args
			local CMD=( "$@" )
		fi

		# trap cleanup EXIT INT TERM
		echo "=========="
		# =================== 执行 bwrap ===================
		# 外层 trap，确保脚本退出时杀掉 bwrap（额外保险）
		# bwrap "${bargs[@]}" -- "$@" # 不source的时候用这段
		bwrap "${bargs[@]}" -- "${CMD[@]}"

		echo "=========="
		echo -e "\n执行清理操作..."
		if [[ -v bwrap_run_from_script ]]; then
			echo "变量 bwrap_run_from_script 已设置"
		unset bwrap_run_from_script
		fi
		# bind_maps_created+=("/tmp/114514")
		for index in "${!bind_maps_created[@]}"; do
			# echo "元素 $index: ${bind_maps_created[$index]}"
			rm -rv "${bind_maps_created[$index]}"
		done
		echo "清理完成。"

	)
}

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
	bwrap_run_from_script=1
	bwrap_run $@
fi

```


## 对于普通应用程序而言
只需要给当前目录权限和`/dev/nvidia*`权限就行了。
> 当然也可以用上面那个版本，只要检测到没有只读直通`$HOME`就是只给当前目录权限、其他目录只读的。



这是完整脚本：
``` shell
#!/usr/bin/env bash

bwrap_run() {
	(
		set -euo pipefail

		# =================== 配置 ===================
		local WORK_DIR="$(pwd)"
		local USER_ID="$(id -u)"
		local GROUP_ID="$(id -g)"

		# 直通只读的文件夹白名单
		local ro_dirs=(
			# 系统配置
			"$HOME/.local/share/fonts"
		)

		# 直通读写的文件夹白名单
		local allowed_dirs=(
			# 直通的目录
			"$HOME/Documents/WIP"
			# Proton
			"$HOME/.local/share/Steam"
			# UV
			"$HOME/.cache/uv"
			"$HOME/.local/share/uv"
			"$HOME/.local/bin/uv" # 官方脚本的安装目录
			# WPS
			"$HOME/.config/Kingsoft"
			"/opt/kingsoft"
			# HMCL
			"$HOME/.local/share/hmcl"
			# Wine Prefix NCM
			"$HOME/Documents/wine_exe"
		)

		# 跨磁盘允许读写用这个加白
		local bind_maps_force=(
		)
		# 跨磁盘允许读写用这个加白, 但只允许从脚本运行时加白
		local bind_maps=(
			"/run/media/$USER/Disk/games::games_here"
		)
		local bind_maps_created=()
		if [[ ! -v bwrap_run_from_script ]]; then
			bind_maps=()
			echo "警告: 从source的函数运行, 跳过挂载bind_maps"
		fi
		# 文件夹映射
		local bind_maps_absloute=(
			"$HOME/Documents/bwrap_home::$HOME"
		)

		# 环境变量
		local env_vars=(
			"LANG=zh_CN.UTF-8"
			"LC_ALL=zh_CN.UTF-8"
			# NVIDIA（有则生效）
			"__GL_THREADED_OPTIMIZATIONS=1"
		)

		# =================== 构建 bwrap 参数 ===================
		local bargs=(
			--unshare-pid		   # 创建独立 PID namespace
			--die-with-parent	   # 父进程退出时 bwrap 自动杀掉
			--setenv HOME "$HOME"
			--setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
			--chdir "$WORK_DIR"
			--tmpfs /tmp	  # 给 bwrap 内程序干净 tmpfs
			--bind /dev/shm /dev/shm   # 对 MIT-SHM 或 X11 必须的共享内存
		)

		echo "===== Device Checking ====="
		# =================== GPU 类型检测 ===================
		detect_gpu() {
			if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
				printf '%s' "nvidia"
				return
			fi
			if ls /dev/nvidia* >/dev/null 2>&1; then
				printf '%s' "nvidia"
				return
			fi
			for card in /sys/class/drm/card*; do
				local vendor_file="$card/device/vendor"
				[ -r "$vendor_file" ] || continue
				local vendor_hex="$(tr -d ' \n' <"$vendor_file")"
				case "$vendor_hex" in
					*8086*) printf 'intel'; return ;;
					*10de*) printf 'nvidia'; return ;;
					*1002*) printf 'intel'; return ;;
				esac
			done
			printf 'unknown'
		}
		local GPU_TYPE="$(detect_gpu || true)"
		echo "检测到 GPU 类型: $GPU_TYPE"
		# =================== GPU 绑定 ===================
		case "$GPU_TYPE" in
			nvidia)
				echo "绑定 NVIDIA 设备节点"
				for ndev in /dev/nvidia*; do
					[ -e "$ndev" ] && bargs+=( --dev-bind "$ndev" "$ndev" )
				done
				[ -d /dev/dri ] && bargs+=( --dev-bind /dev/dri /dev/dri )
			;;
			intel|unknown)
				[ -d /dev/dri ] && bargs+=( --dev-bind /dev/dri /dev/dri )
			;;
		esac

		# =================== XDG_RUNTIME_DIR / Wayland ===================
		local XDG_RUNTIME_DIR="/run/user/$USER_ID"
		local WAYLAND_SOCKET=""
		if [ -d "$XDG_RUNTIME_DIR" ]; then
			for s in "$XDG_RUNTIME_DIR"/wayland-*; do
				[ -S "$s" ] || continue
				local WAYLAND_SOCKET="$s"
				break
			done
		fi
		[ -n "$WAYLAND_SOCKET" ] && echo "Wayland socket: $WAYLAND_SOCKET"
		[ -n "$WAYLAND_SOCKET" ] && bargs+=( --setenv WAYLAND_DISPLAY "$(basename "$WAYLAND_SOCKET")" )

		# =================== 系统库绑定 ===================
		for d in /usr /bin /sbin /etc ; do # /opt
			[ -d "$d" ] && bargs+=( --ro-bind "$d" "$d" )
		done
		[ -d /usr/lib ] && bargs+=( --ro-bind /usr/lib /usr/lib )
		[ -d /usr/lib32 ] && bargs+=( --ro-bind /usr/lib32 /usr/lib32 )
		[ -d /usr/lib32 ] && bargs+=( --ro-bind /usr/lib32 /lib32 )
		[ -d /lib ] && bargs+=( --ro-bind /lib /lib )
		[ -d /lib64 ] && bargs+=( --ro-bind /lib64 /lib64 )
		bargs+=( --proc /proc )
		bargs+=( --ro-bind /sys /sys )
		[ -d /usr/share/fonts ] && bargs+=( --ro-bind /usr/share/fonts /usr/share/fonts )
		# [ -f /etc/resolv.conf ] && bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
		# DNS: Arch 常见是普通文件；Ubuntu 20.04 常见是 /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
		if [ -L /etc/resolv.conf ]; then
			# 只把 systemd-resolved 相关的那部分 /run 带进来，避免整个 /run 都暴露
			if [ -d /run/systemd/resolve ]; then
				bargs+=( --tmpfs /run )
				bargs+=( --ro-bind /run/systemd/resolve /run/systemd/resolve )
			else
				# 极端情况：是链接但宿主机没这个目录，就退回直接 bind（可能仍会失败，但至少有兜底）
				bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
			fi
		else
			[ -f /etc/resolv.conf ] && bargs+=( --ro-bind /etc/resolv.conf /etc/resolv.conf )
		fi

		# ============= 实验室GPU服务器适配 =============
		local HOST_WHITELIST=(
			"gpusrv"
			"y"
		)
		local cur_host="$(hostname -s 2>/dev/null || hostname)"
		for h in "${HOST_WHITELIST[@]}"; do
			if [[ "$cur_host" == "$h" ]]; then
				ro_dirs+=(
					"$HOME/.oh-my-bash"
					"$HOME/.bashrc"
					"$HOME/.profile"
				)
				env_vars+=(
					"FROM_BWRAP=1"
				)
				allowed_dirs+=(
					# 服务器上的
					"$HOME/bwrap_files/transfer"
					"$HOME/tmp"
				)
				# 删除个人电脑上的/home绑定设置，改成服务器专用的
				for i in "${!bind_maps_absloute[@]}"; do
					if [[ "${bind_maps_absloute[i]}" == *"$HOME/Documents/bwrap_home"* ]]; then
						unset 'bind_maps_absloute[i]'
						bind_maps_absloute=("${bind_maps_absloute[@]}")   # 可选：重建索引
						break			   # 只删第一个；要删全部就去掉 break
					fi
				done
				bind_maps_absloute+=("$HOME/bwrap_files/home::$HOME")

				break
			fi
		done

		# =================== /dev & /dev/shm & runtime ===================
		[ -d /dev ] && bargs+=( --dev-bind /dev /dev )
		[ -d /dev/shm ] && bargs+=( --bind /dev/shm /dev/shm )
		[ -d "$XDG_RUNTIME_DIR" ] && bargs+=( --bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" )


		# =================== 用户自定义目录绑定 ===================

		echo "脚本目录: $WORK_DIR"
		echo "用户 HOME: $HOME"
		echo "UID:GID: $USER_ID:$GROUP_ID"

		echo "===== Binding Checking ====="
		echo "ro_dirs:"
		for d in "${ro_dirs[@]}"; do echo "  - $d"; done
		echo "allowed_dirs:"
		for d in "${allowed_dirs[@]}"; do echo "  - $d"; done
		echo "bind_maps:"
		for m in "${bind_maps[@]}"; do echo "  - $m"; done
		echo "bind_maps_force:"
		for m in "${bind_maps_force[@]}"; do echo "  - $m"; done
		echo "bind_maps_absloute:"
		for m in "${bind_maps_absloute[@]}"; do echo "  - $m"; done
		echo "===== Actual Binding ====="
		# =================== 根目录绑定 ===================

		echo "actual bind_maps_absloute:"
		for m in "${bind_maps_absloute[@]}"; do
			host="${m%%::*}"
			target="${m##*::}"
			[ ! -d "$host" ] && echo "$host" && continue
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done
		if [[ "$WORK_DIR" == "$HOME" ]]; then
			echo "警告: WORK_DIR 目录与用户主目录相同! 本次未授权访问主目录"
		else
			bargs+=( --bind "$WORK_DIR" "$WORK_DIR" )
		fi

		# =================== ro_dirs ===================
		for d in "${ro_dirs[@]}"; do
			[ -e "$d" ] && bargs+=( --ro-bind "$d" "$d" )
		done

		# =================== allowed_dirs ===================
		for d in "${allowed_dirs[@]}"; do
			[ -e "$d" ] && bargs+=( --bind "$d" "$d" )
		done

		# =================== 注入环境变量 ===================
		for kv in "${env_vars[@]}"; do
			key="${kv%%=*}"
			val="${kv#*=}"
			bargs+=( --setenv "$key" "$val" )
		done

		# =================== bind_maps ===================
		echo "actual bind_maps:"
		for m in "${bind_maps[@]}"; do
			host="${m%%::*}"
			rel="${m##*::}"
			target="$WORK_DIR/$rel"
			[ ! -d "$host" ] && continue
			[ ! -d "$target" ] && mkdir -p "$target" && bind_maps_created+=("$target")
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done
		echo "actual bind_maps_force:"
		for m in "${bind_maps_force[@]}"; do
			host="${m%%::*}"
			rel="${m##*::}"
			target="$WORK_DIR/$rel"
			[ ! -d "$host" ] && continue
			[ ! -d "$target" ] && mkdir -p "$target" && bind_maps_created+=("$target")
			[ -e "$host" ] && bargs+=( --bind "$host" "$target" )
			echo "  - ${host} -> ${target}"
		done

		echo "===== Cleanup Pending: ====="
		echo "bind_maps_created:"
		for m in "${bind_maps_created[@]}"; do echo "  - $m"; done


		# =================== PATH ===================
		bargs+=( --setenv PATH "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH" )

		# 如果要source的话，这段是需要加上的
		# 1) 注入一个安全的、简洁的 PS1 / 清理会搞事的 prompt 变量
		bargs+=( --setenv PS1 '<sandbox>\u@\h:\w\\$ ' )
		bargs+=( --setenv PROMPT_COMMAND '' )
		bargs+=( --setenv RPROMPT '' )
		bargs+=( --setenv VSCODE_INJECTION '' )  # 视具体环境可选
		# 如果你还有别的在 host 导出的 prompt 变量（比如 ZSH_THEME），也可以在这里清空：
		bargs+=( --setenv ZLE_RPROMPT '' )
		# 2) 决定要执行的命令：若用户传 "bash"，用干净交互 bash；否则执行传入命令
		if [ "${#@}" -ge 1 ] && [ "$1" = "bash" ]; then
			shift
			local CMD=( bash -i "$@" )
		else
			# preserve original args
			local CMD=( "$@" )
		fi

		# trap cleanup EXIT INT TERM
		echo "=========="
		# =================== 执行 bwrap ===================
		# 外层 trap，确保脚本退出时杀掉 bwrap（额外保险）
		# bwrap "${bargs[@]}" -- "$@" # 不source的时候用这段
		bwrap "${bargs[@]}" -- "${CMD[@]}"

		echo "=========="
		echo -e "\n执行清理操作..."
		if [[ -v bwrap_run_from_script ]]; then
			echo "变量 bwrap_run_from_script 已设置"
		unset bwrap_run_from_script
		fi
		# bind_maps_created+=("/tmp/114514")
		for index in "${!bind_maps_created[@]}"; do
			# echo "元素 $index: ${bind_maps_created[$index]}"
			rm -rv "${bind_maps_created[$index]}"
		done
		echo "清理完成。"

	)
}

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
	bwrap_run_from_script=1
	bwrap_run $@
fi

```