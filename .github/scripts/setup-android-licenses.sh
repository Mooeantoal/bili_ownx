#!/bin/bash

# Android SDK 许可证预接受脚本
# 解决 GitHub Actions 构建中的许可证卡住问题

set -e

echo "🔧 开始预配置 Android SDK 许可证..."

# 定义 SDK 路径
SDK_PATH="/usr/local/lib/android/sdk"
LICENSES_PATH="$SDK_PATH/licenses"

# 创建许可证目录
sudo mkdir -p "$LICENSES_PATH"
sudo chmod 755 "$LICENSES_PATH"

# 许可证哈希值
declare -A LICENSES=(
    ["android-sdk-license"]="8933bad161af4178b1185d1a37fbf41ea5269c55"
    ["android-sdk-preview"]="84831b9409646a918e30573bab4c9d966a64d"
    ["google-gdk"]="84831b9409646a918e30573bab4c9d966a64d"
    ["android-sdk-arm-dbt-license"]="d56f5187479451eabf01f78b6430f94631827"
    ["android-sdk-xtend-license"]="24333f8a63b6825ea9c55141383a0746b3326"
    ["android-googletv-license"]="601085b94cd77d045dc5891f2b9bffa8a385"
    ["android-sdk-androidxr-license"]="d975f751698a77b6691ed5e903457d56aeac7c"
)

# 创建许可证文件
for license_file in "${!LICENSES[@]}"; do
    echo "${LICENSES[$license_file]}" | sudo tee "$LICENSES_PATH/$license_file"
    echo "✅ 创建许可证文件: $license_file"
done

# 设置权限
sudo chmod 644 "$LICENSES_PATH"/*

# 创建环境变量文件
echo "export ANDROID_HOME=$SDK_PATH" | sudo tee -a /etc/environment
echo "export ANDROID_SDK_ROOT=$SDK_PATH" | sudo tee -a /etc/environment

echo "✅ Android SDK 许可证预配置完成"
echo "📍 SDK 路径: $SDK_PATH"
echo "📍 许可证路径: $LICENSES_PATH"

# 列出创建的文件
echo "📋 创建的许可证文件:"
ls -la "$LICENSES_PATH"