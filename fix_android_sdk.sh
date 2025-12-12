#!/bin/bash

# Android SDK 35 路径修复脚本
# 解决 android-35 vs android-35-2 路径不匹配问题

echo "=== Android SDK 35 路径修复 ==="
echo "检查当前 SDK 安装状态..."

ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ -z "$ANDROID_SDK_ROOT" ]; then
    ANDROID_SDK_ROOT="$PWD/android-sdk"
fi

echo "SDK 根目录: $ANDROID_SDK_ROOT"

# 检查 platforms 目录
PLATFORMS_DIR="$ANDROID_SDK_ROOT/platforms"
echo "检查 platforms 目录: $PLATFORMS_DIR"

if [ -d "$PLATFORMS_DIR" ]; then
    echo "已安装的 Android 平台:"
    ls -la "$PLATFORMS_DIR" | grep "android"
    
    # 检查是否存在 android-35-2 但不存在 android-35
    if [ -d "$PLATFORMS_DIR/android-35-2" ] && [ ! -d "$PLATFORMS_DIR/android-35" ]; then
        echo "发现 android-35-2，创建 android-35 符号链接..."
        
        # 创建符号链接
        ln -sf "$PLATFORMS_DIR/android-35-2" "$PLATFORMS_DIR/android-35"
        
        if [ -L "$PLATFORMS_DIR/android-35" ]; then
            echo "✓ 成功创建 android-35 符号链接指向 android-35-2"
            ls -la "$PLATFORMS_DIR/android-35"
        else
            echo "❌ 创建符号链接失败，尝试复制..."
            cp -r "$PLATFORMS_DIR/android-35-2" "$PLATFORMS_DIR/android-35"
            if [ -d "$PLATFORMS_DIR/android-35" ]; then
                echo "✓ 成功复制 android-35-2 到 android-35"
            else
                echo "❌ 复制也失败了"
                exit 1
            fi
        fi
    elif [ -d "$PLATFORMS_DIR/android-35" ]; then
        echo "✓ android-35 已存在，无需修复"
    else
        echo "❌ 未找到 android-35-2 或 android-35"
        echo "尝试安装 Android SDK 35..."
        
        # 使用 sdkmanager 安装 platform
        if [ -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
            "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --install "platforms;android-35"
        else
            echo "❌ sdkmanager 不可用"
            exit 1
        fi
    fi
    
else
    echo "❌ platforms 目录不存在"
    exit 1
fi

echo ""
echo "=== 验证修复结果 ==="
if [ -d "$PLATFORMS_DIR/android-35" ]; then
    echo "✓ android-35 现在可用"
    echo "路径: $PLATFORMS_DIR/android-35"
    echo "内容:"
    ls -la "$PLATFORMS_DIR/android-35" | head -10
else
    echo "❌ android-35 仍然不可用"
    exit 1
fi

echo ""
echo "=== 检查构建工具 ==="
BUILD_TOOLS_DIR="$ANDROID_SDK_ROOT/build-tools"
if [ -d "$BUILD_TOOLS_DIR" ]; then
    echo "已安装的构建工具:"
    ls -la "$BUILD_TOOLS_DIR" | grep -E "^[d].*35"
    
    if [ ! -d "$BUILD_TOOLS_DIR/35.0.0" ]; then
        echo "尝试安装构建工具 35.0.0..."
        if [ -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
            "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --install "build-tools;35.0.0"
        fi
    fi
else
    echo "❌ build-tools 目录不存在"
fi

echo ""
echo "=== 修复完成 ==="
echo "现在可以重新运行 Flutter 构建"