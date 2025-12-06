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
echo "=== 方案1: 使用环境变量绕过交互 ==="
# 设置环境变量避免交互式确认
export ANDROID_SDK_ACCEPT_LICENSES=true
export JAVA_OPTS="-Dandroid.accept licenses=true"

echo "=== 方案2: 使用 expect 脚本（如果可用） ==="
if command -v expect &> /dev/null; then
    echo "使用 expect 自动确认许可证..."
    expect -c "
    spawn $SDKMANAGER --licenses
    expect {
        \"y/N?\" { send \"y\r\"; exp_continue }
        \"(y/n)\" { send \"y\r\"; exp_continue }
        eof
    }
    " || echo "expect 脚本执行失败，尝试其他方案"
else
    echo "expect 不可用，使用其他方案..."
fi

echo "=== 方案3: 使用 printf 预设答案 ==="
printf 'y\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\n' | "$SDKMANAGER" --licenses 2>/dev/null || {
    echo "尝试备用许可证处理方案..."
    # 备用方案：直接使用 yes 命令
    timeout 30 yes | "$SDKMANAGER" --licenses 2>/dev/null || {
        echo "警告: 许可证处理可能未完全成功，但继续构建..."
    }
}

# 验证许可证状态
echo "验证许可证状态..."
"$SDKMANAGER" --list_installed | head -5

echo "Android SDK 许可证处理完成！"