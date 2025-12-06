#!/bin/bash

echo "=== 强制构建 APK ==="

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicenses=true"

echo "=== 完全清理 ==="
flutter clean
rm -rf build/
cd android
chmod +x gradlew
./gradlew clean
rm -rf .gradle/
rm -rf build/
cd ..

echo "=== 修改 Flutter 配置 ==="
# 尝试通过环境变量覆盖 ABI 配置
export FLUTTER_BUILD_MODE=debug
export GRADLE_USER_HOME=$HOME/.gradle

echo "=== 获取依赖 ==="
flutter pub get

echo "=== 直接使用 Gradle 构建 ==="
cd android

# 临时修复 ABI 冲突
echo "applying abi fix..."
sed -i '/splits {/,/}/{s/isEnable = true/isEnable = false/}' app/build.gradle.kts

# 构建
./gradlew assembleDebug --stacktrace --info

cd ..

echo "=== 检查结果 ==="
if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "✅ 构建成功！"
    cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/flutter-apk/ -f
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
else
    echo "❌ 构建失败"
fi