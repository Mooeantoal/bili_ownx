#!/bin/bash

# 最小化APK构建脚本
# 用于生成体积最小化的APK

echo "🚀 开始构建最小化APK..."

# 清理项目
echo "🧹 清理项目缓存..."
flutter clean
cd android
./gradlew clean
cd ..

# 获取依赖
echo "📦 获取项目依赖..."
flutter pub get

# 构建分析
echo "📊 分析项目依赖..."
flutter pub deps --style=tree

# 构建最小化APK (仅arm64-v8a架构)
echo "🔨 构建最小化APK (arm64-v8a)..."
flutter build apk --release \
  --shrink \
  --split-per-abi \
  --target-platform android-arm64

# 检查构建结果
echo "📏 检查APK大小..."
APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
if [ -f "$APK_PATH" ]; then
    SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
    echo "✅ 构建成功!"
    echo "📦 APK路径: $APK_PATH"
    echo "📏 APK大小: $SIZE"
    
    # 显示详细分析
    echo ""
    echo "📊 APK分析详情:"
    echo "   - 架构: arm64-v8a (主流64位架构)"
    echo "   - 优化: R8混淆 + 资源压缩 + ABI分离"
    echo "   - 兼容: Android 5.0+ (API 21+)"
else
    echo "❌ 构建失败!"
    exit 1
fi

echo ""
echo "🎯 优化建议:"
echo "   1. 如需支持更多设备，可构建armeabi-v7a版本"
echo "   2. 可考虑移除不必要的依赖包"
echo "   3. 使用bundle格式进一步减小体积"

echo ""
echo "✨ 构建完成!"