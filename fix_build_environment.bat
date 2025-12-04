@echo off
echo ========================================
echo BiliOwnx 构建环境修复脚本
echo ========================================
echo.

echo 1. 检查 Flutter 安装...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter 未安装或不在 PATH 中
    echo 请先安装 Flutter: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)
echo ✅ Flutter 已安装
echo.

echo 2. 检查 Android SDK...
if exist "%LOCALAPPDATA%\Android\Sdk" (
    echo ✅ 找到 Android SDK: %LOCALAPPDATA%\Android\Sdk
    set SDK_PATH=%LOCALAPPDATA%\Android\Sdk
) else if exist "C:\Android\Sdk" (
    echo ✅ 找到 Android SDK: C:\Android\Sdk
    set SDK_PATH=C:\Android\Sdk
) else (
    echo ❌ 未找到 Android SDK
    echo 请按照 ANDROID_SDK_SETUP.md 指南安装 Android SDK
    pause
    exit /b 1
)
echo.

echo 3. 更新 local.properties...
echo flutter.sdk=%FLUTTER_ROOT% > android\local.properties
echo sdk.dir=%SDK_PATH% >> android\local.properties
echo ✅ 已更新 android\local.properties
echo.

echo 4. 检查 Java...
java -version
if %errorlevel% neq 0 (
    echo ❌ Java 未安装
    echo 请安装 JDK 17 或更高版本
    pause
    exit /b 1
)
echo ✅ Java 已安装
echo.

echo 5. 接受 Android 许可证...
echo y | flutter doctor --android-licenses
echo.

echo 6. 清理项目...
flutter clean
echo.

echo 7. 获取依赖...
flutter pub get
echo.

echo 8. 尝试构建...
echo 开始构建 APK (Debug)...
flutter build apk --debug
if %errorlevel% equ 0 (
    echo ✅ 构建成功！
    echo APK 文件位置: build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo ❌ 构建失败
    echo 请查看上方的错误信息
)
echo.

echo ========================================
echo 修复脚本执行完成
echo ========================================
pause