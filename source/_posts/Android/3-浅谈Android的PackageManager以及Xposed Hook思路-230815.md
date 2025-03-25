---
title: 浅谈Android的PackageManager以及Xposed Hook思路
category: Android
date: 2023-08-15 18:00:00
index_img: https://tse3-mm.cn.bing.net/th/id/OIP-C.FpgNGT5YM2WJrH6VabbaiAHaDt?pid=ImgDet&rs=1
---

![封面](https://tse3-mm.cn.bing.net/th/id/OIP-C.FpgNGT5YM2WJrH6VabbaiAHaDt?pid=ImgDet&rs=1)

# 前情提要
最近穹轨挺火~~*，室友天天原神启动，搞得我也想来一个星穹铁道启动*~~在b站上看到网友整活，CR200J启动以及往12306里疯狂氪金648的流水账单~~*，为了蹭个热度就来整个烂活*~~

既然是个Android爱好者，那肯定得从Android开发的角度来整这个烂活。于是我就打算通过xposed插件实现在不改包的情况下将包名为`com.MobileTiket`的`铁路12306`app图标和名称替换为`星穹铁道`。


# 技术选型
既然是通过`Xposed`模块来实现这个功能，那一定要考虑好模块要hook谁。我们要的效果是能在系统桌面、系统设置、最近任务等地方实现这个效果。但又考虑到不同的软件显示图标的逻辑肯定不一样，那我们只能从更底层的地方去进行hook。于是我选择了Android的包管理服务。

~~当然直接hook`android.widget.TextView`也不是不行，但样有亿点过于生草~~


# 原理分析
在Android中，一个app想要根据包名获取别的app名称以及图标，通常的思路就是先获取当前上下文里的PackageManager
``` kotin
val pm = packageManager // 获取PackageManager
val appinfo = pm.getApplicationInfo("com.MobileTicket", flags) // 获取ApplicationInfo
binding.testtv.text = appinfo.loadLabel(pm) // 现在建议用的获取应用名的方法
binding.testtv.text = pm.getApplicationLabel(appinfo) // 之前常用的，不过现在底层实现也是上面的方法warp了一下
binding.testiv.background = pm.getApplicationIcon(appinfo) // 获取应用程序图标
```

## 获取应用程序标题
> 我们在写app的时候，不难发现在`AndroidManifest.xml`中的`application`字段下的`android:label`键值就是应用程序名称。

对这段代码在Android Studio里逐行ctrl左键，我们发现：
`Context.getPackageManager()`调用的是`android.content.ContextWrapper`下的`getPackageManager()`方法，这个方法返回的是`android.content.Context.getPackageManager()'方法。看看源码：
``` java
/** Return PackageManager instance to find global package information. */
public abstract PackageManager getPackageManager();
```
完蛋，这是个抽象方法，因为Xposed无法hook抽象类及以下的抽象方法。不过问题不大，这一步获取到的packagemanager也不包含我们需要query的包名`com.MobileTicket`。接着下一步！

`val appinfo = pm.getApplicationInfo("com.MobileTicket", flags)`这段代码的`getApplicationInfo()`方法，位于`android.content.pm.PackageManager`下
``` java
/**
* Return the label to use for this application.
*
* @return Returns a {@link CharSequence} containing the label associated with
* this application, or its name the  item does not have a label.
* @param info The {@link ApplicationInfo} of the application to get the label of.
*/
@NonNull
public abstract CharSequence getApplicationLabel(@NonNull ApplicationInfo info);
```
我一看，啊完蛋，又是个抽象方法。只能连上adb打断点debug了。
一步一步跟踪代码运行过程，发现它运行到了`android.app.ApplicationPackageManager`下的`getApplicationLabel()`方法：
``` java
@Override
public CharSequence getApplicationLabel(ApplicationInfo info) {
    return info.loadLabel(this);
}
```
你看到了啥？对没错，`@Override`！这是重写了一个父类的方法？重写了谁的？把源码拉到最顶上看看：
``` java
public class ApplicationPackageManager extends PackageManager {
```
好耶，是PackageManager！
在经过多次调试之后，发现这个类就是实现了之前的抽象类PackageManager的子类！
再深究以下，发现这个`getApplicationLabel()`方法调用的是形参`info`的`loadLabel()`方法，再进行ctrl左键进去看看，发现和上面第三行`binding.testtv.text = appinfo.loadLabel(pm)`调用的方法一致，位于`android.content.pm.PackageItemInfo`下。看看源码:
``` java
 /**
 * Retrieve the current textual label associated with this item.  This
 * will call back on the given PackageManager to load the label from
 * the application.
 *
 * @param pm A PackageManager from which the label can be loaded; usually
 * the PackageManager from which you originally retrieved this item.
 *
 * @return Returns a CharSequence containing the item's label.  If the
 * item does not have a label, its name is returned.
 */
public @NonNull CharSequence loadLabel(@NonNull PackageManager pm) {
    if (sForceSafeLabels && !Objects.equals(packageName, ActivityThread.currentPackageName())) {
        return loadSafeLabel(pm, DEFAULT_MAX_LABEL_SIZE_PX, SAFE_STRING_FLAG_TRIM
                | SAFE_STRING_FLAG_FIRST_LINE);
    } else {
        // Trims the label string to the MAX_SAFE_LABEL_LENGTH. This is to prevent that the
        // system is overwhelmed by an enormous string returned by the application.
        return TextUtils.trimToSize(loadUnsafeLabel(pm), MAX_SAFE_LABEL_LENGTH);
    }
}
```
ok,看来这就是源头的方法了，返回一个CharSequence对象。经过一番debug发现，它返回的就是`铁路12306`。好，直接对其进行hook就行。它后续会视情况调用`loadSafeLabel`和`loadUnsafeLabel`方法，但最终还会返回`铁路12306`这个CharSequence对象，所以无需再去hook那些子方法了。~~*放在一边备用*~~

## 获取应用程序图标
> 同样在`AndroidManifest.xml`下的`application`字段下，有`android:icon`和`android:roundIcon`两个键值，对应的分别是方形图标和圆角图标。~~在此我们不需要对其进行区分，只需要一股脑hook就完事了~~

同样对上面的代码进行ctrl左键，发现`pm.getApplicationIcon(appinfo)`这段代码调用的源码居然还是个抽象方法:
```java
/**
 * Retrieve the icon associated with an application.  If it has not defined
 * an icon, the default app icon is returned.  Does not return null.
 *
 * @param info Information about application being queried.
 *
 * @return Returns the image of the icon, or the default application icon
 * if it could not be found.
 *
 * @see #getApplicationIcon(String)
 */
@NonNull
public abstract Drawable getApplicationIcon(@NonNull ApplicationInfo info);
```
但是没关系，我们之前不是发现`android.app.ApplicationPackageManager`实现了PackageManager类吗？带着假设去它里面翻，果然翻到了实现函数：
``` java
@Override public Drawable getApplicationIcon(ApplicationInfo info) {
    return info.loadIcon(this);
}
```
哦豁，又是老套路调用ApplicationInfo的方法，再ctrl左键进去，发现跟上面的`loadLabel`一样换汤不换药，还在`android.content.pm.PackageItemInfo`下的同一个位置：
``` java
/**
 * Retrieve the current graphical icon associated with this item.  This
 * will call back on the given PackageManager to load the icon from
 * the application.
 *
 * @param pm A PackageManager from which the icon can be loaded; usually
 * the PackageManager from which you originally retrieved this item.
 *
 * @return Returns a Drawable containing the item's icon.  If the
 * item does not have an icon, the item's default icon is returned
 * such as the default activity icon.
 */
public Drawable loadIcon(PackageManager pm) {
    return pm.loadItemIcon(this, getApplicationInfo());
}
```
~~*放到一边备用*~~


# Xposed hook思路分析
好的，既然我们上面已经拿到了几个要hook的方法，我们来总结一下：
``` java
// 获取应用程序名称的方法，位于`android.content.pm.PackageItemInfo`下
public @NonNull CharSequence loadLabel(@NonNull PackageManager pm) {
    if (sForceSafeLabels && !Objects.equals(packageName, ActivityThread.currentPackageName())) {
        return loadSafeLabel(pm, DEFAULT_MAX_LABEL_SIZE_PX, SAFE_STRING_FLAG_TRIM
                | SAFE_STRING_FLAG_FIRST_LINE);
    } else {
        // Trims the label string to the MAX_SAFE_LABEL_LENGTH. This is to prevent that the
        // system is overwhelmed by an enormous string returned by the application.
        return TextUtils.trimToSize(loadUnsafeLabel(pm), MAX_SAFE_LABEL_LENGTH);
    }
}

// 获取应用程序图标的方法，位于`android.content.pm.PackageItemInfo`下
public Drawable loadIcon(PackageManager pm) {
    return pm.loadItemIcon(this, getApplicationInfo());
}
```

先是编写了测试代码，对这些方法进行无差别的hook:
``` kotlin
findMethod("android.content.pm.PackageItemInfo") {
    name == "loadLabel" && returnType == CharSequence::class.java && paramCount == 1 && isNotStatic && isPublic
}.hookBefore {
    it.result = newAppLabel
}

findMethod("android.content.pm.PackageItemInfo") {
    name == "loadIcon" && returnType == Drawable::class.java && paramCount == 1 && isNotStatic && isPublic
}.hookBefore {
    val bytes: ByteArray = Base64.decode(newIconBase64, Base64.DEFAULT)
    val myBitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    it.result = BitmapDrawable(myBitmap)
}
```
作用域勾选系统框架和系统桌面，发现效果很不错，手机桌面上的图标和应用名都变成了`星穹铁道`
好的，我们接下来就是要进行包名过滤，仅对获取`com.MobieTicket`的请求返回`星穹铁道`。

仔细分析上面我们放着备用的AOSP源码里的方法，会发现它在区分包名的时候并不是通过形参，而是通过判断当前类中的`packageName`变量值来判断你query的是谁的信息。
通过全局搜索，能看到在这个文件里有关于这个变量的定义:
``` java
/**
 * Name of the package that this item is in.
 */
public String packageName;
```
诶嘿，那我直接用获取当前内存里的`packageName`对象并转换成`String`类，判断其中的值是否为`com.MobileTicket`就行了呗
> 在debug之后验证了这个猜想
开干！加个if条件：
``` kotlin
if(it.thisObject.getObjectAs<String>("packageName", String::class.java) == "com.MobileTicket")
```


# 最终的核心代码
``` kotlin
fun hookIcon(goalPkgName:String, newIconBase64:String){
    findMethod("android.content.pm.PackageItemInfo") {
        name == "loadIcon" && returnType == Drawable::class.java && paramCount == 1 && isNotStatic && isPublic
    }.hookBefore {
        if ((it.thisObject.getObjectAs<String>("packageName", String::class.java) == goalPkgName) || (it.thisObject.getObjectAs<String>("packageName", String::class.java) == goalPkgName)) {
            val bytes: ByteArray = Base64.decode(newIconBase64, Base64.DEFAULT)
            val myBitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            it.result = BitmapDrawable(myBitmap)
        }
    }
}

fun hookLabel(goalPkgName:String, newAppLabel:String){
/*    findMethod("android.app.ApplicationPackageManager") {
        name == "getText" && returnType == CharSequence::class.java && isNotStatic && isPublic
    }.hookBefore {
        if (it.args[0] == goalPkgName) {
            it.result = newAppLabel
        }
    }*/

    findMethod("android.content.pm.PackageItemInfo") {
        name == "loadLabel" && returnType == CharSequence::class.java && paramCount == 1 && isNotStatic && isPublic
    }.hookBefore {
        val packageName = it.thisObject.getObjectAs<String>("packageName", String::class.java)
        if (packageName == goalPkgName) {
            it.result = newAppLabel
        }
    }
}
```

# 运行效果
<iframe src="//player.bilibili.com/player.html?aid=960104472&bvid=BV1Yp4y1K7wa" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>


# 源码地址
本项目已开源在[Github](https://github.com/CoolestEnoch/AndroidAppIconSwitcher)上