# 修复依赖版本冲突

Write-Host "=== 修复依赖版本冲突 ===" -ForegroundColor Green

# 检查当前Flutter版本
Write-Host "检查当前Flutter版本..."
flutter --version

Write-Host ""
Write-Host "=== 修复方案 ===" -ForegroundColor Yellow
Write-Host "1. 升级SDK约束到 >=3.4.0 (推荐)"
Write-Host "2. 降级shared_preferences到2.2.3"
Write-Host "3. 两者都尝试"
Write-Host ""

$choice = Read-Host "请选择方案 (1-3)"

switch ($choice) {
    "1" {
        Write-Host "=== 升级SDK约束 ===" -ForegroundColor Cyan
        (Get-Content pubspec.yaml) -replace "sdk: '>=3.3.0 <4.0.0'", "sdk: '>=3.4.0 <4.0.0'" | Set-Content pubspec.yaml
        Write-Host "已升级SDK约束到 >=3.4.0" -ForegroundColor Green
    }
    "2" {
        Write-Host "=== 降级shared_preferences ===" -ForegroundColor Cyan
        (Get-Content pubspec.yaml) -replace "shared_preferences: \^2.3.2", "shared_preferences: ^2.2.3" | Set-Content pubspec.yaml
        Write-Host "已降级shared_preferences到2.2.3" -ForegroundColor Green
    }
    "3" {
        Write-Host "=== 同时应用两种修复 ===" -ForegroundColor Cyan
        $content = Get-Content pubspec.yaml
        $content = $content -replace "sdk: '>=3.3.0 <4.0.0'", "sdk: '>=3.4.0 <4.0.0'"
        $content = $content -replace "shared_preferences: \^2.3.2", "shared_preferences: ^2.2.3"
        $content | Set-Content pubspec.yaml
        Write-Host "已同时升级SDK约束并降级shared_preferences" -ForegroundColor Green
    }
    default {
        Write-Host "无效选择，退出" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== 清理并重新获取依赖 ===" -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host ""
Write-Host "=== 验证修复结果 ===" -ForegroundColor Yellow
flutter doctor --verbose
Write-Host ""
Write-Host "=== 如果仍有问题，请检查Flutter版本是否支持Dart 3.4.0+ ===" -ForegroundColor Cyan