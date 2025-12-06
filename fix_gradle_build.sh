#!/bin/bash

echo "=== 修复 Gradle 构建问题 ==="

# 设置正确的环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicenses=true"

echo "=== 清理构建缓存 ==="
flutter clean
cd android && ./gradlew clean && cd ..

echo "=== 重新获取依赖 ==="
flutter pub get

echo "=== 构建 Debug APK ==="
flutter build apk --debug

echo "=== 如果构建成功，APK位置: build/app/outputs/flutter-apk/app-debug.apk ==="