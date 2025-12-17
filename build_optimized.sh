#!/bin/bash

echo "🚀 Flutter优化构建脚本"
echo "========================"

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或未在PATH中"
    exit 1
fi

# 检查项目
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在Flutter项目根目录运行此脚本"
    exit 1
fi

echo "🔍 检查项目状态..."
flutter doctor

echo
echo "🧹 清理旧缓存..."
if [ -d "build" ]; then
    rm -rf build
    echo "✓ 清理build目录"
fi

if [ -d ".dart_tool" ]; then
    rm -rf .dart_tool
    echo "✓ 清理.dart_tool目录"
fi

if [ -d ".gradle" ]; then
    rm -rf .gradle
    echo "✓ 清理.gradle目录"
fi

echo
echo "📦 获取依赖..."
flutter packages get

echo
echo "🔧 优化Android构建..."
cd android
./gradlew clean
./gradlew build --build-cache --parallel --daemon --configure-on-demand
cd ..

echo
echo "🎯 执行优化构建..."
echo "选择构建类型:"
echo "1) Debug快速构建"
echo "2) Release优化构建"  
echo "3) Profile分析构建"
read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo "🚀 构建Debug版本..."
        flutter build apk --debug --no-pub --target-platform android-arm64
        ;;
    2)
        echo "🏗️ 构建Release版本..."
        flutter build apk --release --no-pub --split-per-abi --shrink
        ;;
    3)
        echo "📊 构建Profile版本..."
        flutter build apk --profile --no-pub --target-platform android-arm64
        ;;
    *)
        echo "❌ 无效选择，使用默认Debug构建"
        flutter build apk --debug --no-pub
        ;;
esac

echo
echo "✅ 构建完成！"
echo "📱 APK位置: build/app/outputs/flutter-apk/"

echo
echo "💡 提示:"
echo "- 下次构建将更快 (缓存已启用)"
echo "- 使用 'flutter run' 进行热重载开发"
echo "- 查看 flutter_build_optimization.md 了解更多优化"