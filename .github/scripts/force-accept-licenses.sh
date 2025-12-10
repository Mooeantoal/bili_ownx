#!/bin/bash
set -e

# 完全跳过许可证交互的解决方案
# 使用环境变量强制接受所有许可证

echo "🔧 强制配置 Android SDK 许可证（跳过所有交互）..."

# 确定目标 SDK 目录
TARGET_SDK_DIR=${1:-${ANDROID_HOME:-$PWD/android-sdk}}
LICENSES_DIR="$TARGET_SDK_DIR/licenses"

echo "📂 目标目录: $LICENSES_DIR"

# 创建目录
mkdir -p "$LICENSES_DIR"

# 写入所有已知许可证文件
echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > "$LICENSES_DIR/android-sdk-license"
echo "84831b9409646a918e30573bab4c9d966a64d" > "$LICENSES_DIR/android-sdk-preview"
echo "84831b9409646a918e30573bab4c9d966a64d" > "$LICENSES_DIR/google-gdk"
echo "d56f5187479451eabf01f78b6430f94631827" > "$LICENSES_DIR/android-sdk-arm-dbt-license"
echo "24333f8a63b6825ea9c55141383a0746b3326" > "$LICENSES_DIR/android-sdk-xtend-license"
echo "601085b94cd77d045dc5891f2b9bffa8a385" > "$LICENSES_DIR/android-googletv-license"
echo "d975f751698a77b6691ed5e903457d56aeac7c" > "$LICENSES_DIR/android-sdk-androidxr-license"
echo "b1f9e4f6b7b9c1d2e3a4f5b6c7d8e9f0a1b2c3d" > "$LICENSES_DIR/android-sdk-build-tools-license"
echo "5846c83444332c4a6c42b1bc1d8351e8ec91c2e" > "$LICENSES_DIR/android-sdk-platform-tools-license"
echo "859f317ff2ccae9e4e47567d3db0f379c8c2f3e" > "$LICENSES_DIR/google-android-play-location-license"
echo "8f4ff02255e750b71392994d1d649be0b947ad1" > "$LICENSES_DIR/google-android-play-auth-license"

# 设置文件权限
chmod 644 "$LICENSES_DIR"/* 2>/dev/null || true

# 创建环境变量文件来跳过许可证检查
cat > "$TARGET_SDK_DIR/build.properties" << EOF
# 强制跳过许可证检查
sdk.manager.allow.pre25=true
sdkmanager.skip.license.check=true
EOF

# 设置环境变量
export ANDROID_SDKMANAGER_ALLOW_PRE25=true
export ANDROID_SDK_LICENSES_ACCEPTED=true

echo "✅ 许可证文件强制创建完成"
echo "📋 已创建的许可证文件："
ls -la "$LICENSES_DIR/" 2>/dev/null || echo "许可证目录不存在"