#!/bin/bash

# 强制接受 Android SDK 许可证脚本
# 使用多种方法确保许可证被接受

echo "=== 强制接受 Android SDK 许可证 ==="

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

# 方法1: 环境变量
echo "=== 方法1: 设置环境变量 ==="
export ANDROID_SDK_ACCEPT_LICENSES=true
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ACCEPT_LICENSES=true

# 方法2: 创建许可证文件
echo "=== 方法2: 创建许可证文件 ==="
mkdir -p "$ANDROID_HOME/licenses"
echo "8933bad161af4178b1185d1a37fbf41ea5269c55d" > "$ANDROID_HOME/licenses/android-sdk-license"
echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
echo "24333f8a63b6825ea9c5514e83c0e9a993a0a6f" > "$ANDROID_HOME/licenses/google-gdk"
echo "84831b9409646a918e30573bab4c9c91346b8b90" > "$ANDROID_HOME/licenses/android-sdk-arm-dbt-license"
echo "598de3781d13c8c5df5a678110464d3863734768" > "$ANDROID_HOME/licenses/android-sdk-google-license"

# 方法3: 使用 expect
echo "=== 方法3: 使用 expect ==="
if command -v expect &> /dev/null; then
    echo "使用 expect 自动确认..."
    timeout 60 expect -c "
    log_user 0
    spawn $SDKMANAGER --licenses
    expect {
        \"y/N?\" { send \"y\r\"; exp_continue }
        \"(y/n)\" { send \"y\r\"; exp_continue }
        \"Accept? (y/N)\" { send \"y\r\"; exp_continue }
        timeout { exit 0 }
        eof { exit 0 }
    }
    " 2>/dev/null || echo "expect 超时或失败"
fi

# 方法4: 使用 printf
echo "=== 方法4: 使用 printf ==="
timeout 60 bash -c "
    for i in {1..20}; do
        echo 'y'
    done
" | "$SDKMANAGER" --licenses 2>/dev/null || echo "printf 方法完成（可能有警告）"

# 方法5: 使用 yes
echo "=== 方法5: 使用 yes ==="
timeout 60 yes | "$SDKMANAGER" --licenses 2>/dev/null || echo "yes 方法完成（可能有警告）"

# 验证结果
echo "=== 验证许可证状态 ==="
ls -la "$ANDROID_HOME/licenses/" 2>/dev/null || echo "许可证目录不存在"
echo "已安装的组件："
"$SDKMANAGER" --list_installed 2>/dev/null | head -5 || echo "无法列出已安装组件"

echo "=== 许可证强制处理完成 ==="