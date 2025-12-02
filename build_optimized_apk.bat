@echo off
REM 构建优化后的 APK 脚本 (Windows 版本)

echo 🔧 开始构建优化后的 APK...

REM 清理项目
echo 📦 清理项目...
flutter clean

REM 获取依赖
echo 📥 获取依赖...
flutter pub get

REM 构建 release APK (arm64-v8a)
echo 🏗️ 构建 arm64-v8a 版本...
flutter build apk --release --target-platform android-arm64

REM 构建 release APK (armeabi-v7a)  
echo 🏗️ 构建 armeabi-v7a 版本...
flutter build apk --release --target-platform android-arm

REM 构建 appbundle (推荐用于发布)
echo 📦 构建 App Bundle...
flutter build appbundle --release

echo.
echo ✅ 构建完成！
echo.
echo 📱 生成的文件位置：
echo    - arm64-v8a APK: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo    - armeabi-v7a APK: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo    - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo 💡 提示：
echo    - App Bundle (.aab) 是推荐的发布格式
echo    - APK 文件用于测试和侧载安装
echo    - arm64-v8a 适用于大多数现代设备
echo    - armeabi-v7a 适用于较老的设备
echo.
echo 📊 查看文件大小：
if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" dir "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" dir "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk"
if exist "build\app\outputs\bundle\release\app-release.aab" dir "build\app\outputs\bundle\release\app-release.aab"

pause