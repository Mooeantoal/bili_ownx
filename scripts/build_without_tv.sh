#!/bin/bash

# 尝试排除 Google TV 组件的构建脚本

echo "=== 尝试构建不包含 TV 组件的版本 ==="

# 备份原始文件
cp android/app/build.gradle.kts android/app/build.gradle.kts.backup

echo "1. 降低 SDK 版本..."
# 临时修改 build.gradle.kts 以降低 SDK 版本
sed -i 's/compileSdk = 35/compileSdk = 34/' android/app/build.gradle.kts
sed -i 's/targetSdk = 35/targetSdk = 34/' android/app/build.gradle.kts

echo "2. 清理构建缓存..."
flutter clean
rm -rf android/.gradle

echo "3. 获取依赖..."
flutter pub get

echo "4. 尝试构建..."
export ANDROID_SDK_ACCEPT_LICENSES=true
export ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.accept licenses=true"

flutter build apk --debug

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo "APK 位置: build/app/outputs/flutter-apk/app-debug.apk"
else
    echo "❌ 构建失败，恢复原始配置..."
    git checkout android/app/build.gradle.kts
    echo "可能需要接受 Google TV 许可证"
fi