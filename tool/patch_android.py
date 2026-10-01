"""Vá thư mục android/ do `flutter create` sinh ra: quyền, receiver thông báo, desugaring."""
import pathlib
import re

m = pathlib.Path("android/app/src/main/AndroidManifest.xml")
s = m.read_text(encoding="utf-8")
perms = (
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
    '<uses-permission android:name="android.permission.VIBRATE"/>\n'
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
    '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>\n'
)
recv = (
    '<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>\n'
    '<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">'
    '<intent-filter>'
    '<action android:name="android.intent.action.BOOT_COMPLETED"/>'
    '<action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>'
    '<action android:name="android.intent.action.QUICKBOOT_POWERON"/>'
    '<action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>'
    '</intent-filter></receiver>\n'
)
if "POST_NOTIFICATIONS" not in s:
    s = s.replace("<application", perms + "<application", 1)
    s = s.replace("</application>", recv + "</application>", 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="LifeSync"', s, count=1)
m.write_text(s, encoding="utf-8")

for name in ("build.gradle.kts", "build.gradle"):
    f = pathlib.Path("android/app") / name
    if not f.exists():
        continue
    g = f.read_text(encoding="utf-8")
    if "coreLibraryDesugaring" in g or "CoreLibraryDesugaring" in g:
        break
    if name.endswith(".kts"):
        g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    else:
        g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    f.write_text(g, encoding="utf-8")
    break
print("Android patched")
