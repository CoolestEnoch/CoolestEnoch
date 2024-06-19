---
title: Android12的SplashScreen适配
category: Android
date: 2023-08-23 18:00:00
index_img: https://www.gstatic.cn/devrel-devsite/prod/vf01e53c189c374f4b844e7f928194555d40bd3ee38d62d21b64d81f753f3c6a2/android/images/rebrand/lockup.svg
---

![封面](https://www.gstatic.cn/devrel-devsite/prod/vf01e53c189c374f4b844e7f928194555d40bd3ee38d62d21b64d81f753f3c6a2/android/images/rebrand/lockup.svg)

废话不多说，直接上代码

添加到themes.xml中，然后把需要展示的activity的theme设置为这个就行。当然也可以直接在application字段下全局设置，这样冷启动的时候就会展示splashscreen

``` xml
<style name="MySplashScreen" parent="@style/Theme.崩坏丶12306">
    <item name="windowActionBar">false</item>
    <item name="windowNoTitle">true</item>
    <!-- 启动画面背景颜色 -->
    <item name="android:windowSplashScreenBackground">@color/material_dynamic_neutral20</item>
    <!-- 启动画面中间显示的图标，默认使用应用图标 -->
    <item name="android:windowSplashScreenAnimatedIcon">@mipmap/appicon</item>
    <!-- 启动画面中间显示的图标的背景，如果图标背景不透明则无效 -->
    <item name="android:windowSplashScreenIconBackgroundColor">@color/material_dynamic_neutral50</item>
    <!-- 启动画面启动画面底部的图片。 -->
    <item name="android:windowSplashScreenBrandingImage">@mipmap/splash12306</item>
    <!-- 启动画面在关闭之前显示的时长。最长时间为 1000 毫秒。 -->
    <item name="android:windowSplashScreenAnimationDuration">1000</item>
</style>
```

~~*好耶又水了一篇文*~~