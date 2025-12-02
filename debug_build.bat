@echo off
REM 构建调试版本以测试修复

echo 🔧 构建调试版本...

REM 清理项目
echo 📦 清理项目...
flutter clean

REM 获取依赖
echo 📥 获取依赖...
flutter pub get

REM 构建 debug APK
echo 🏗️ 构建 debug APK...
flutter build apk --debug

echo.
echo ✅ 构建完成！
echo.
echo 📱 调试 APK 位置：build\app\outputs\flutter-apk\app-debug.apk
echo.
echo 💡 调试提示：
echo   - 安装后测试搜索功能
echo   - 观察控制台输出的调试信息
echo   - 检查视频项的解析结果
echo   - 验证 BVID 和 AID 是否正确获取
echo.
echo 📊 查看文件大小：
if exist "build\app\outputs\flutter-apk\app-debug.apk" dir "build\app\outputs\flutter-apk\app-debug.apk"

pause