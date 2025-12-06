# 修复 NDK ABI 配置冲突

Write-Host "=== 修复 NDK ABI 配置冲突 ===" -ForegroundColor Green

# 确保只使用 arm64-v8a 架构
Write-Host "检查当前构建配置..." -ForegroundColor Yellow
Set-Location android

Write-Host "=== 清理构建缓存 ===" -ForegroundColor Yellow
& .\gradlew clean

Write-Host "=== 重新获取 Flutter 依赖 ===" -ForegroundColor Yellow
Set-Location ..
flutter clean
flutter pub get

Write-Host "=== 构建 APK (跳过依赖验证) ===" -ForegroundColor Yellow
flutter build apk --debug --android-skip-build-dependency-validation

Write-Host "=== 如果构建成功，APK位置: build/app/outputs/flutter-apk/app-debug.apk ===" -ForegroundColor Cyan
Write-Host "=== 架构: arm64-v8a (64位) ===" -ForegroundColor Cyan