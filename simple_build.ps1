# 简单构建脚本

Write-Host "=== 简单构建脚本 ===" -ForegroundColor Green

# 设置环境变量
$env:ANDROID_SDK_ACCEPT_LICENSES = "true"
$env:GRADLE_OPTS = "-Dandroid.acceptLicenses=true"

Write-Host "=== 完全清理 ===" -ForegroundColor Yellow
flutter clean
Set-Location android
& .\gradlew clean
Remove-Item -Recurse -Force .gradle -ErrorAction SilentlyContinue
Set-Location ..

Write-Host "=== 重新获取依赖 ===" -ForegroundColor Yellow
flutter pub get

Write-Host "=== 构建 APK ===" -ForegroundColor Yellow
flutter build apk --debug --android-skip-build-dependency-validation

Write-Host "=== 检查构建结果 ===" -ForegroundColor Cyan
if (Test-Path "build/app/outputs/flutter-apk/app-debug.apk") {
    Write-Host "✅ 构建成功！" -ForegroundColor Green
    Get-ChildItem "build/app/outputs/flutter-apk/app-debug.apk" | Format-List Name, Length
} else {
    Write-Host "❌ 构建失败" -ForegroundColor Red
}