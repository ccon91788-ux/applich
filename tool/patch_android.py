"""Vá thư mục android/ do `flutter create` sinh ra: quyền, receiver thông báo, desugaring, compileSdk."""
import pathlib
import re

COMPILE_SDK = "36"

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
    # Nâng compileSdk (thư viện AndroidX mới yêu cầu 36+)
    g = re.sub(
        r"compileSdk(?:Version)?(\s*=\s*|\s+)flutter\.compileSdkVersion",
        r"compileSdk\g<1>" + COMPILE_SDK,
        g,
    )
    if "esugaring" not in g:
        if name.endswith(".kts"):
            g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
            g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        else:
            g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
            g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    f.write_text(g, encoding="utf-8")
    print("--- " + name)
    for line in g.splitlines():
        if "compileSdk" in line or "esugaring" in line:
            print(line.strip())
    break
print("Android patched")

# --- Ép mọi plugin (subproject) dùng compileSdk 36 ---
KTS_HOOK = """subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            val m = ext.javaClass.methods.firstOrNull {
                it.name == "compileSdkVersion" && it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            }
            m?.invoke(ext, %s)
        }
    }
}

""" % COMPILE_SDK
GROOVY_HOOK = """subprojects {
    afterEvaluate { p ->
        if (p.hasProperty('android')) {
            p.android.compileSdkVersion %s
        }
    }
}

""" % COMPILE_SDK

for name, hook in (("build.gradle.kts", KTS_HOOK), ("build.gradle", GROOVY_HOOK)):
    f = pathlib.Path("android") / name
    if not f.exists():
        continue
    g = f.read_text(encoding="utf-8")
    if "compileSdkVersion" not in g:
        i = g.find("subprojects {")
        # Phải đăng ký TRƯỚC khối evaluationDependsOn(":app")
        g = (g[:i] + hook + g[i:]) if i >= 0 else (g + "\n" + hook)
        f.write_text(g, encoding="utf-8")
    print("root " + name + " patched")
    break
