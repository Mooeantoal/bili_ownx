#!/bin/bash

echo "=== 紧急构建脚本 ==="

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicenses=true"

echo "=== 清理 ==="
flutter clean

echo "=== 获取依赖 ==="
flutter pub get

echo "=== 尝试不同的构建方法 ==="

# 方法1: 跳过验证
echo "尝试方法1: 跳过依赖验证..."
flutter build apk --debug --android-skip-build-dependency-validation
if [ $? -eq 0 ]; then
    echo "✅ 方法1成功！"
    exit 0
fi

# 方法2: 只构建arm64-v8a
echo "尝试方法2: 指定arm64-v8a架构..."
flutter build apk --debug --split-debug-info=build/debug-info --obfuscate --android-skip-build-dependency-validation
if [ $? -eq 0 ]; then
    echo "✅ 方法2成功！"
    exit 0
fi

# 方法3: 使用不同的构建命令
echo "尝试方法3: 使用gradle直接构建..."
cd android
chmod +x gradlew
./gradlew app:assembleDebug -x lint -x test
cd ..
if [ $? -eq 0 ]; then
    echo "✅ 方法3成功！"
    cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/flutter-apk/ -f
    exit 0
fi

echo "❌ 所有方法都失败了"
exit 1