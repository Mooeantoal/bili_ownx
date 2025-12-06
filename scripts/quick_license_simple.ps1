# 简化版快速许可证修复脚本

Write-Host "=== Quick Android SDK License Fix ==="

if (-not $env:ANDROID_HOME) {
    Write-Host "Error: ANDROID_HOME not set"
    exit 1
}

Write-Host "Android SDK: $env:ANDROID_HOME"

# Set environment variables
$env:ANDROID_SDK_ACCEPT_LICENSES = "true"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ACCEPT_LICENSES = "true"

# Create license directory
$licenseDir = "$env:USERPROFILE\.android\licenses"
New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null

# Create license files
"android-sdk-license", "8933bad161af4178b1185d1a37fbf41ea5269c55d" -join "`n" | Out-File -FilePath "$licenseDir\android-sdk-license" -Encoding UTF8
"android-googletv-license", "601085b53c84555a2897545eb1f38b296baeb1b5" -join "`n" | Out-File -FilePath "$licenseDir\android-googletv-license" -Encoding UTF8
"android-sdk-preview-license", "d56f5187479451eabf01fb78af6dfcb131a6481e" -join "`n" | Out-File -FilePath "$licenseDir\android-sdk-preview-license" -Encoding UTF8
"google-gdk", "84831b9409646a918e30573bab4c9c91346b8b90" -join "`n" | Out-File -FilePath "$licenseDir\google-gdk" -Encoding UTF8

Write-Host "License files created successfully!"
Get-ChildItem $licenseDir | ForEach-Object { Write-Host "  $($_.Name)" }

Write-Host "License fix complete!"
Write-Host "You can now run: flutter build apk --debug"