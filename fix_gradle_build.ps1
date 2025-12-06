# 修复 Gradle 构建问题

Write-Host "=== 修复 Gradle 构建问题 ===" -ForegroundColor Green

# 设置正确的环境变量
$env:ANDROID_SDK_ACCEPT_LICENSES = "true"
$env:GRADLE_OPTS = "-Dandroid.acceptLicenses=true"

Write-Host "=== 清理构建缓存 ===" -ForegroundColor Yellow
flutter clean
Set-Location android
& .\gradlew clean
Set-Location ..

Write-Host "=== 重新获取依赖 ===" -ForegroundColor Yellow
flutter pub get

Write-Host "=== 构建 Debug APK ===" -ForegroundColor Yellow
flutter build apk --debug --android-skip-build-dependency-validation

Write-Host "=== 如果构建成功，APK位置: build/app/outputs/flutter-apk/app-debug.apk ===" -ForegroundColor Cyan