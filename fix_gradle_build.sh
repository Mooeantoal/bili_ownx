#!/bin/bash

echo "=== 修复 Gradle 构建问题 ==="

# 清理构建缓存
echo "清理构建缓存..."
cd android
./gradlew clean

# 回到项目根目录
cd ..

# 清理 Flutter 缓存
echo "清理 Flutter 缓存..."
flutter clean

# 重新获取依赖
echo "重新获取依赖..."
flutter pub get

# 升级依赖
echo "升级依赖到最新兼容版本..."
flutter pub upgrade --major-versions

# 重新构建
echo "重新构建项目..."
flutter build apk --debug

echo "=== 构建修复完成 ==="