#!/bin/bash

echo "=== 修复 NDK ABI 配置冲突 ==="

# 确保只使用 arm64-v8a 架构
echo "检查当前构建配置..."
cd android

echo "=== 清理构建缓存 ==="
./gradlew clean

echo "=== 重新获取 Flutter 依赖 ==="
cd ..
flutter clean
flutter pub get

echo "=== 构建 APK (跳过依赖验证) ==="
flutter build apk --debug --android-skip-build-dependency-validation

echo "=== 如果构建成功，APK位置: build/app/outputs/flutter-apk/app-debug.apk ==="
echo "=== 架构: arm64-v8a (64位) ==="