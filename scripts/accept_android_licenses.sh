#!/bin/bash

# Android SDK 许可证自动接受脚本
# 解决 CI 构建中的许可证交互问题

echo "=== Android SDK 许可证自动处理 ==="

# 检查 ANDROID_HOME 是否设置
if [ -z "$ANDROID_HOME" ]; then
    echo "错误: ANDROID_HOME 环境变量未设置"
    exit 1
fi

# 检查 sdkmanager 是否存在
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [ ! -f "$SDKMANAGER" ]; then
    echo "警告: sdkmanager 未找到，尝试其他路径..."
    SDKMANAGER="$ANDROID_HOME/tools/bin/sdkmanager"
    if [ ! -f "$SDKMANAGER" ]; then
        echo "错误: sdkmanager 未找到"
        exit 1
    fi
fi

echo "使用 sdkmanager: $SDKMANAGER"

# 预设答案以自动接受所有许可证
echo "正在自动接受 Android SDK 许可证..."
# 使用 printf 预设答案，避免 yes 命令可能的超时问题
printf 'y\ny\ny\ny\ny\ny\ny\n' | "$SDKMANAGER" --licenses || {
    echo "尝试备用许可证处理方案..."
    # 备用方案：直接使用 yes 命令
    yes | "$SDKMANAGER" --licenses || {
        echo "警告: 许可证处理可能未完全成功，但继续构建..."
    }
}

# 验证许可证状态
echo "验证许可证状态..."
"$SDKMANAGER" --list_installed | head -5

echo "Android SDK 许可证处理完成！"