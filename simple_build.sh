#!/bin/bash

echo "=== 简单构建脚本 ==="

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicenses=true"

echo "=== 完全清理 ==="
flutter clean
cd android
./gradlew clean
rm -rf .gradle/
cd ..

echo "=== 重新获取依赖 ==="
flutter pub get

echo "=== 构建 APK ==="
flutter build apk --debug --android-skip-build-dependency-validation

echo "=== 检查构建结果 ==="
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✅ 构建成功！"
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
else
    echo "❌ 构建失败"
fi