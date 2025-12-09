#!/bin/bash

echo "🔧 预配置 Android SDK 许可证..."

# 直接创建许可证文件到多个可能的位置
mkdir -p $ANDROID_HOME/licenses 2>/dev/null || true
mkdir -p /usr/local/lib/android/sdk/licenses 2>/dev/null || true
mkdir -p $HOME/android-sdk/licenses 2>/dev/null || true

# 创建许可证文件
echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > android-sdk-license
echo "84831b9409646a918e30573bab4c9d966a64d" > android-sdk-preview
echo "84831b9409646a918e30573bab4c9d966a64d" > google-gdk
echo "d56f5187479451eabf01f78b6430f94631827" > android-sdk-arm-dbt-license
echo "24333f8a63b6825ea9c55141383a0746b3326" > android-sdk-xtend-license
echo "601085b94cd77d045dc5891f2b9bffa8a385" > android-googletv-license
echo "d975f751698a77b6691ed5e903457d56aeac7c" > android-sdk-androidxr-license

# 复制到所有可能的许可证目录
cp android-sdk-license $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-sdk-license /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-sdk-license $HOME/android-sdk/licenses/ 2>/dev/null || true

cp android-sdk-preview $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-sdk-preview /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-sdk-preview $HOME/android-sdk/licenses/ 2>/dev/null || true

cp google-gdk $ANDROID_HOME/licenses/ 2>/dev/null || true
cp google-gdk /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp google-gdk $HOME/android-sdk/licenses/ 2>/dev/null || true

cp android-sdk-arm-dbt-license $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-sdk-arm-dbt-license /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-sdk-arm-dbt-license $HOME/android-sdk/licenses/ 2>/dev/null || true

cp android-sdk-xtend-license $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-sdk-xtend-license /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-sdk-xtend-license $HOME/android-sdk/licenses/ 2>/dev/null || true

cp android-googletv-license $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-googletv-license /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-googletv-license $HOME/android-sdk/licenses/ 2>/dev/null || true

cp android-sdk-androidxr-license $ANDROID_HOME/licenses/ 2>/dev/null || true
cp android-sdk-androidxr-license /usr/local/lib/android/sdk/licenses/ 2>/dev/null || true
cp android-sdk-androidxr-license $HOME/android-sdk/licenses/ 2>/dev/null || true

echo "✅ 许可证文件创建完成"

# 清理临时文件
rm -f android-sdk-license android-sdk-preview google-gdk android-sdk-arm-dbt-license android-sdk-xtend-license android-googletv-license android-sdk-androidxr-license