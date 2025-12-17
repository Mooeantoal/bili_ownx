@echo off
echo 🚀 Flutter优化构建脚本
echo ========================

:: 检查Flutter是否安装
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter未安装或未在PATH中
    pause
    exit /b 1
)

echo 🔍 检查项目状态...
flutter doctor

echo.
echo 🧹 清理旧缓存...
if exist build (
    rmdir /s /q build
)
if exist .dart_tool (
    rmdir /s /q .dart_tool
)
if exist .gradle (
    rmdir /s /q .gradle
)

echo.
echo 📦 获取依赖...
flutter packages get

echo.
echo 🔧 优化Android构建...
cd android
call gradlew clean
call gradlew build --build-cache --parallel --daemon --configure-on-demand
cd ..

echo.
echo 🎯 执行优化构建...
set CHOICE=
set /p CHOICE=选择构建类型 (1=Debug快速, 2=Release优化, 3=Profile分析): 

if "%CHOICE%"=="1" (
    echo 🚀 构建Debug版本...
    flutter build apk --debug --no-pub --target-platform android-arm64
) else if "%CHOICE%"=="2" (
    echo 🏗️ 构建Release版本...
    flutter build apk --release --no-pub --split-per-abi --shrink
) else if "%CHOICE%"=="3" (
    echo 📊 构建Profile版本...
    flutter build apk --profile --no-pub --target-platform android-arm64
) else (
    echo ❌ 无效选择，使用默认Debug构建
    flutter build apk --debug --no-pub
)

echo.
echo ✅ 构建完成！
echo 📱 APK位置: build\app\outputs\flutter-apk\

echo.
echo 💡 提示:
echo - 下次构建将更快 (缓存已启用)
echo - 使用 'flutter run' 进行热重载开发
echo - 查看 flutter_build_optimization.md 了解更多优化

pause