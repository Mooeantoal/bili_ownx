#!/bin/bash

# 测试许可证修复效果的脚本
# 用于验证许可证问题是否已解决

echo "=== 测试许可证修复效果 ==="

# 检查环境
if [ -z "$ANDROID_HOME" ]; then
    echo "错误: ANDROID_HOME 未设置"
    exit 1
fi

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -f "$SDKMANAGER" ]; then
    SDKMANAGER="$ANDROID_HOME/tools/bin/sdkmanager"
fi

if [ ! -f "$SDKMANAGER" ]; then
    echo "错误: sdkmanager 未找到"
    exit 1
fi

echo "使用 SDK Manager: $SDKMANAGER"

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ACCEPT_LICENSES=true

# 1. 测试许可证文件状态
echo "=== 测试1: 检查许可证文件状态 ==="

if [ -d "$ANDROID_HOME/licenses" ]; then
    echo "✅ $ANDROID_HOME/licenses 目录存在"
    ls -la "$ANDROID_HOME/licenses/"
    
    # 检查关键许可证
    for license_file in "android-sdk-license" "android-googletv-license" "android-sdk-preview-license" "google-gdk"; do
        if [ -f "$ANDROID_HOME/licenses/$license_file" ]; then
            echo "✅ $license_file 存在"
        else
            echo "❌ $license_file 缺失"
        fi
    done
else
    echo "❌ $ANDROID_HOME/licenses 目录不存在"
fi

# 检查用户许可证目录
USER_LICENSE_DIR="$HOME/.android/licenses"
if [ -d "$USER_LICENSE_DIR" ]; then
    echo "✅ 用户许可证目录存在: $USER_LICENSE_DIR"
    ls -la "$USER_LICENSE_DIR/"
fi

# 2. 测试 sdkmanager 许可证状态
echo "=== 测试2: 检查 sdkmanager 许可证状态 ==="

# 尝试检查许可证状态（非交互式）
echo "检查已安装的组件..."
if timeout 30 "$SDKMANAGER" --list_installed >/dev/null 2>&1; then
    echo "✅ sdkmanager 可以正常运行"
    "$SDKMANAGER" --list_installed | head -5
else
    echo "❌ sdkmanager 运行有问题，尝试许可证处理..."
    
    # 尝试快速许可证处理
    echo "尝试快速许可证处理..."
    timeout 60 bash -c "
        for i in {1..20}; do
            echo 'y'
            sleep 0.1
        done
    " | "$SDKMANAGER" --licenses >/dev/null 2>&1 || echo "许可证处理完成（可能有警告）"
fi

# 3. 测试构建命令
echo "=== 测试3: 检查构建环境 ==="

if [ -f "android/app/build.gradle.kts" ]; then
    echo "✅ build.gradle.kts 存在"
    
    # 检查语法
    if grep -q "minSdk = 21" android/app/build.gradle.kts; then
        echo "⚠️  发现语法错误: minSdk = 21"
    elif grep -q "minSdkVersion(21)" android/app/build.gradle.kts; then
        echo "✅ minSdkVersion 语法正确"
    else
        echo "⚠️  未找到 minSdkVersion 配置"
    fi
else
    echo "❌ build.gradle.kts 不存在"
fi

# 4. 测试 Flutter 环境
echo "=== 测试4: 检查 Flutter 环境 ==="
if command -v flutter &> /dev/null; then
    echo "✅ Flutter 可用"
    echo "Flutter 版本:"
    flutter --version | head -2
    
    # 测试 Flutter 依赖
    if [ -f "pubspec.yaml" ]; then
        echo "测试 Flutter 依赖..."
        if timeout 30 flutter pub get >/dev/null 2>&1; then
            echo "✅ Flutter 依赖正常"
        else
            echo "⚠️  Flutter 依赖获取可能有问题"
        fi
    fi
else
    echo "❌ Flutter 不可用"
fi

# 5. 模拟构建测试
echo "=== 测试5: 模拟构建测试 ==="

if command -v flutter &> /dev/null && [ -f "android/app/build.gradle.kts" ]; then
    echo "尝试模拟构建（仅检查语法和配置）..."
    
    # 设置环境变量
    export GRADLE_OPTS="-Dandroid.accept licenses=true -Dandroid.licenses.accepted=true"
    
    # 仅检查 Gradle 语法，不实际构建
    cd android
    if timeout 60 ./gradlew assembleDebug --dry-run >/dev/null 2>&1; then
        echo "✅ Gradle 配置检查通过"
    else
        echo "⚠️  Gradle 配置可能有问题"
    fi
    cd ..
fi

echo "=== 许可证修复测试完成 ==="
echo "如果所有关键项目都显示 ✅，则许可证问题已解决"