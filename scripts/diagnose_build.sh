#!/bin/bash

# 构建环境诊断脚本
# 用于诊断构建失败的原因

echo "=== 构建环境诊断 ==="

echo "=== 基础信息 ==="
echo "工作目录: $(pwd)"
echo "JAVA_HOME: $JAVA_HOME"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"

echo "=== Java 版本 ==="
java -version 2>&1
echo "javac 版本:"
javac -version 2>&1

echo "=== Flutter 版本 ==="
flutter --version

echo "=== Android SDK 信息 ==="
if [ -n "$ANDROID_HOME" ]; then
    echo "Android SDK 路径: $ANDROID_HOME"
    echo "SDK Manager 路径: $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    
    if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
        echo "✅ SDK Manager 存在"
        echo "已安装的包:"
        $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list_installed 2>/dev/null | head -10 || echo "无法列出已安装包"
    else
        echo "❌ SDK Manager 不存在"
    fi
    
    echo "许可证目录:"
    if [ -d "$ANDROID_HOME/licenses" ]; then
        ls -la "$ANDROID_HOME/licenses/"
        echo "许可证文件检查:"
        for license_file in android-sdk-license android-googletv-license android-sdk-preview-license google-gdk; do
            if [ -f "$ANDROID_HOME/licenses/$license_file" ]; then
                echo "✅ $license_file"
            else
                echo "❌ $license_file (缺失)"
            fi
        done
    else
        echo "❌ 许可证目录不存在"
    fi
    
    echo "平台目录:"
    ls -la "$ANDROID_HOME/platforms/" 2>/dev/null | head -5 || echo "无平台目录"
    
    echo "构建工具目录:"
    ls -la "$ANDROID_HOME/build-tools/" 2>/dev/null | head -5 || echo "无构建工具目录"
else
    echo "❌ ANDROID_HOME 未设置"
fi

echo "=== Gradle 信息 ==="
if [ -f "android/gradlew" ]; then
    cd android
    echo "Gradle 版本:"
    ./gradlew --version 2>/dev/null || echo "无法获取 Gradle 版本"
    cd ..
else
    echo "❌ Gradle wrapper 不存在"
fi

echo "=== 构建文件检查 ==="
echo "build.gradle.kts 存在性:"
if [ -f "android/app/build.gradle.kts" ]; then
    echo "✅ android/app/build.gradle.kts 存在"
    echo "minSdkVersion 配置:"
    grep -n "minSdk" android/app/build.gradle.kts || echo "未找到 minSdk 配置"
else
    echo "❌ android/app/build.gradle.kts 不存在"
fi

echo "=== 依赖检查 ==="
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml 存在"
    echo "Flutter 依赖检查:"
    flutter pub deps 2>/dev/null | head -10 || echo "依赖检查失败"
else
    echo "❌ pubspec.yaml 不存在"
fi

echo "=== 环境变量 ==="
echo "ANDROID_SDK_ACCEPT_LICENSES: $ANDROID_SDK_ACCEPT_LICENSES"
echo "ACCEPT_LICENSES: $ACCEPT_LICENSES"

echo "=== 诊断完成 ==="