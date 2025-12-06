#!/bin/bash

# Android SDK 许可证诊断脚本
# 用于诊断和解决许可证相关问题

echo "=== Android SDK 许可证诊断 ==="

# 检查环境变量
echo "1. 检查环境变量:"
echo "ANDROID_HOME: ${ANDROID_HOME:-未设置}"
echo "JAVA_HOME: ${JAVA_HOME:-未设置}"

if [ -z "$ANDROID_HOME" ]; then
    echo "错误: ANDROID_HOME 未设置"
    exit 1
fi

# 检查 SDK Manager
echo "2. 检查 SDK Manager:"
SDKMANAGER_PATHS=(
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    "$ANDROID_HOME/tools/bin/sdkmanager"
    "$ANDROID_HOME/cmdline-tools/bin/sdkmanager"
)

SDKMANAGER=""
for path in "${SDKMANAGER_PATHS[@]}"; do
    if [ -f "$path" ]; then
        SDKMANAGER="$path"
        echo "找到 SDK Manager: $path"
        break
    fi
done

if [ -z "$SDKMANAGER" ]; then
    echo "错误: 未找到 SDK Manager"
    exit 1
fi

# 检查许可证状态
echo "3. 检查当前许可证状态:"
echo "已安装的包:"
"$SDKMANAGER" --list_installed 2>/dev/null | head -10 || echo "无法列出已安装包"

# 尝试处理许可证
echo "4. 尝试自动接受许可证:"
echo "使用 printf 预设答案..."
printf 'y\ny\ny\ny\ny\ny\ny\ny\ny\n' | "$SDKMANAGER" --licenses 2>&1 | head -20

# 再次检查
echo "5. 验证许可证处理结果:"
if timeout 10 "$SDKMANAGER" --licenses > /dev/null 2>&1; then
    echo "✅ 许可证处理成功"
else
    echo "❌ 许可证可能仍有问题"
    echo "尝试 yes 命令..."
    timeout 10 yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 && echo "✅ 备用方案成功"
fi

echo "=== 诊断完成 ==="