#!/bin/bash

echo "=== 带权限修复的构建脚本 ==="

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicenses=true"

echo "=== 清理 ==="
flutter clean

echo "=== 修复 gradlew 权限 ==="
cd android
chmod +x gradlew

echo "=== 验证 Gradle 环境 ==="
./gradlew --version
if [ $? -ne 0 ]; then
    echo "❌ Gradle 无法执行，尝试使用本地 Gradle"
    # 如果 gradlew 失败，尝试使用系统 gradle
    if command -v gradle &> /dev/null; then
        echo "使用系统 Gradle..."
        gradle assembleDebug
    else
        echo "❌ 系统中也没有 Gradle"
        exit 1
    fi
else
    echo "✅ Gradle 可以正常执行"
    
    echo "=== 清理 Gradle 缓存 ==="
    ./gradlew clean
    
    cd ..
    
    echo "=== 获取 Flutter 依赖 ==="
    flutter pub get
    
    cd android
    
    echo "=== 构建 APK ==="
    ./gradlew assembleDebug
fi

cd ..

echo "=== 检查构建结果 ==="
if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "✅ 构建成功！"
    mkdir -p build/app/outputs/flutter-apk/
    cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/flutter-apk/
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
else
    echo "❌ 构建失败"
fi