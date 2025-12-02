#!/bin/bash

echo "测试 APK 构建"
echo "============"

echo "1. 清理环境"
flutter clean
rm -rf build/
rm -rf android/app/build/

echo "2. 获取依赖"
flutter pub get

echo "3. 检查 Flutter 配置"
flutter doctor -v

echo "4. 尝试构建 APK (通用)"
flutter build apk --debug --verbose

echo "5. 检查生成的文件"
echo "当前目录 APK 文件："
find . -name "*.apk" -type f -ls 2>/dev/null || echo "未找到 APK 文件"

echo "build 目录结构："
find build -type f -name "*.apk" -ls 2>/dev/null || echo "build 目录中无 APK 文件"

echo "Android 构建目录："
find android/app/build -type f -name "*.apk" -ls 2>/dev/null || echo "Android 构建目录中无 APK 文件"

echo "6. 尝试拆分构建（如果通用构建失败）"
flutter build apk --debug --split-per-abi --verbose

echo "7. 再次检查文件"
find . -name "*.apk" -type f -ls 2>/dev/null || echo "拆分构建后仍未找到 APK 文件"