# PowerShell 版本的快速许可证修复脚本

Write-Host "=== 快速接受 Android SDK 许可证 (PowerShell版) ==="

# 检查环境变量
if (-not $env:ANDROID_HOME) {
    Write-Host "错误: ANDROID_HOME 环境变量未设置" -ForegroundColor Red
    exit 1
}

Write-Host "Android SDK 路径: $env:ANDROID_HOME"

# 设置环境变量
$env:ANDROID_SDK_ACCEPT_LICENSES = "true"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ACCEPT_LICENSES = "true"
$env:GRADLE_OPTS = "-Dandroid.accept licenses=true -Dandroid.licenses.accepted=true"

# 创建用户许可证目录
$userLicenseDir = "$env:USERPROFILE\.android\licenses"
New-Item -ItemType Directory -Path $userLicenseDir -Force | Out-Null
Write-Host "用户许可证目录: $userLicenseDir"

# 创建许可证文件
$licenses = @{
    "android-sdk-license" = "8933bad161af4178b1185d1a37fbf41ea5269c55d"
    "android-googletv-license" = "601085b53c84555a2897545eb1f38b296baeb1b5"
    "android-sdk-preview-license" = "d56f5187479451eabf01fb78af6dfcb131a6481e"
    "google-gdk" = "84831b9409646a918e30573bab4c9c91346b8b90"
    "android-sdk-google-license" = "598de3781d13c8c5df5a678110464d3863734768"
    "android-sdk-arm-dbt-license" = "24333f8a63b6825ea9c5514e83c0e9a993a0a6f"
    "intel-android-extra-license" = "33b6a2b64607111b2893360c6b44c7a64512267"
    "mips-android-extra-license" = "84831b9409646a918e30573bab4c9c91346b8b90"
}

Write-Host "创建许可证文件..."
foreach ($license in $licenses.GetEnumerator()) {
    $filePath = Join-Path $userLicenseDir $license.Key
    $license.Value | Out-File -FilePath $filePath -Encoding UTF8
    Write-Host "✅ 创建: $($license.Key)" -ForegroundColor Green
}

Write-Host "`n许可证文件创建完成:"
Get-ChildItem $userLicenseDir | ForEach-Object {
    Write-Host "  $($_.Name)"
}

# 设置许可证路径
$env:ANDROID_SDK_LICENSE_PATH = $userLicenseDir

Write-Host "`n=== 许可证处理完成 ==="
Write-Host "现在可以运行构建命令:" -ForegroundColor Yellow
Write-Host "flutter clean" -ForegroundColor Cyan
Write-Host "flutter pub get" -ForegroundColor Cyan
Write-Host "flutter build apk --debug" -ForegroundColor Cyan

# 询问是否立即构建
$choice = Read-Host "`n是否立即开始构建? (y/n)"
if ($choice -eq 'y' -or $choice -eq 'Y') {
    Write-Host "`n开始构建..."
    try {
        flutter clean
        flutter pub get
        flutter build apk --debug
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nBuild successful!" -ForegroundColor Green
            Write-Host "APK location: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Yellow
        } else {
            Write-Host "`nBuild failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "`nBuild error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "License ready, you can build manually later" -ForegroundColor Yellow
}