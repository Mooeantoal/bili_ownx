# BiliOwnx 构建环境修复脚本 (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BiliOwnx 构建环境修复脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 Flutter 安装
Write-Host "1. 检查 Flutter 安装..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter 已安装" -ForegroundColor Green
    Write-Host $flutterVersion
} catch {
    Write-Host "❌ Flutter 未安装或不在 PATH 中" -ForegroundColor Red
    Write-Host "请先安装 Flutter: https://flutter.dev/docs/get-started/install/windows"
    Read-Host "按回车键退出"
    exit 1
}
Write-Host ""

# 2. 检查 Android SDK
Write-Host "2. 检查 Android SDK..." -ForegroundColor Yellow
$sdkPath = $null
$possiblePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "C:\Android\Sdk",
    "D:\Android\Sdk"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $sdkPath = $path
        Write-Host "✅ 找到 Android SDK: $path" -ForegroundColor Green
        break
    }
}

if (-not $sdkPath) {
    Write-Host "❌ 未找到 Android SDK" -ForegroundColor Red
    Write-Host "请按照 ANDROID_SDK_SETUP.md 指南安装 Android SDK"
    Read-Host "按回车键退出"
    exit 1
}
Write-Host ""

# 3. 更新 local.properties
Write-Host "3. 更新 local.properties..." -ForegroundColor Yellow
$flutterRoot = $env:FLUTTER_ROOT
if (-not $flutterRoot) {
    # 尝试从 flutter 命令获取路径
    $flutterPath = (Get-Command flutter).Source
    $flutterRoot = Split-Path (Split-Path $flutterPath)
}

$localPropertiesPath = "android\local.properties"
$propertiesContent = @"
flutter.sdk=$flutterRoot
sdk.dir=$sdkPath
"@

Set-Content -Path $localPropertiesPath -Value $propertiesContent -Encoding UTF8
Write-Host "✅ 已更新 android\local.properties" -ForegroundColor Green
Write-Host ""

# 4. 检查 Java
Write-Host "4. 检查 Java..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1
    Write-Host "✅ Java 已安装" -ForegroundColor Green
    Write-Host $javaVersion[0]
} catch {
    Write-Host "❌ Java 未安装" -ForegroundColor Red
    Write-Host "请安装 JDK 17 或更高版本"
    Read-Host "按回车键退出"
    exit 1
}
Write-Host ""

# 5. 接受 Android 许可证
Write-Host "5. 接受 Android 许可证..." -ForegroundColor Yellow
Write-Host "y" | flutter doctor --android-licenses
Write-Host ""

# 6. 清理项目
Write-Host "6. 清理项目..." -ForegroundColor Yellow
flutter clean
Write-Host ""

# 7. 获取依赖
Write-Host "7. 获取依赖..." -ForegroundColor Yellow
flutter pub get
Write-Host ""

# 8. 尝试构建
Write-Host "8. 尝试构建..." -ForegroundColor Yellow
Write-Host "开始构建 APK (Debug)..." -ForegroundColor Cyan
$buildResult = flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 构建成功！" -ForegroundColor Green
    Write-Host "APK 文件位置: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Cyan
} else {
    Write-Host "❌ 构建失败" -ForegroundColor Red
    Write-Host "请查看上方的错误信息" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "修复脚本执行完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "按回车键退出"