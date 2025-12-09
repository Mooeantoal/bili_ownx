#!/bin/bash
set -e

# 确定目标 SDK 目录
# 优先使用传入参数，其次是 ANDROID_HOME，最后是当前目录下的 android-sdk
TARGET_SDK_DIR=${1:-${ANDROID_HOME:-$PWD/android-sdk}}
LICENSES_DIR="$TARGET_SDK_DIR/licenses"

echo "🔧 配置 Android SDK 许可证..."
echo "📂 目标目录: $LICENSES_DIR"

# 创建目录
mkdir -p "$LICENSES_DIR"

# 写入许可证文件
# 这些 hash 值对应 Android SDK 各组件的许可证协议
echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > "$LICENSES_DIR/android-sdk-license"
echo "84831b9409646a918e30573bab4c9d966a64d" > "$LICENSES_DIR/android-sdk-preview"
echo "84831b9409646a918e30573bab4c9d966a64d" > "$LICENSES_DIR/google-gdk"
echo "d56f5187479451eabf01f78b6430f94631827" > "$LICENSES_DIR/android-sdk-arm-dbt-license"
echo "24333f8a63b6825ea9c55141383a0746b3326" > "$LICENSES_DIR/android-sdk-xtend-license"
echo "601085b94cd77d045dc5891f2b9bffa8a385" > "$LICENSES_DIR/android-googletv-license"
echo "d975f751698a77b6691ed5e903457d56aeac7c" > "$LICENSES_DIR/android-sdk-androidxr-license"

echo "✅ 许可证文件已创建于: $LICENSES_DIR"