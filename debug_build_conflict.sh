#!/bin/bash

echo "=== 调试构建冲突 ==="

cd android

echo "=== 使用 --stacktrace 获取详细错误信息 ==="
./gradlew assembleDebug --stacktrace --info

echo ""
echo "=== 检查项目配置 ==="
./gradlew projects

echo ""
echo "=== 检查 Android 配置 ==="
./gradlew app:androidComponents

echo ""
echo "=== 强制清理所有缓存 ==="
./gradlew clean
./gradlew cleanBuildCache
rm -rf .gradle/
cd ..
flutter clean

echo ""
echo "=== 尝试最小化构建 ==="
flutter build apk --debug --android-skip-build-dependency-validation --verbose