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

# 方法0: 环境变量（最优先）
echo "=== 方法0: 设置环境变量 ==="
export ANDROID_SDK_ACCEPT_LICENSES=true
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ACCEPT_LICENSES=true

# 方法1: 预创建所有许可证文件（最重要）
echo "=== 方法1: 预创建许可证文件 ==="
if mkdir -p "$ANDROID_HOME/licenses" 2>/dev/null; then
    echo "成功创建许可证目录"
    
    # 创建所有可能的许可证文件
    cat > "$ANDROID_HOME/licenses/android-sdk-license" 2>/dev/null << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c55d
EOF
    
    cat > "$ANDROID_HOME/licenses/android-sdk-preview-license" 2>/dev/null << 'EOF'
d56f5187479451eabf01fb78af6dfcb131a6481e
EOF
    
    cat > "$ANDROID_HOME/licenses/google-gdk" 2>/dev/null << 'EOF'
84831b9409646a918e30573bab4c9c91346b8b90
EOF
    
    cat > "$ANDROID_HOME/licenses/android-sdk-google-license" 2>/dev/null << 'EOF'
598de3781d13c8c5df5a678110464d3863734768
EOF
    
    cat > "$ANDROID_HOME/licenses/android-sdk-arm-dbt-license" 2>/dev/null << 'EOF'
24333f8a63b6825ea9c5514e83c0e9a993a0a6f
EOF
    
    cat > "$ANDROID_HOME/licenses/intel-android-extra-license" 2>/dev/null << 'EOF'
33b6a2b64607111b2893360c6b44c7a64512267
EOF
    
    cat > "$ANDROID_HOME/licenses/mips-android-extra-license" 2>/dev/null << 'EOF'
84831b9409646a918e30573bab4c9c91346b8b90
EOF
    
    cat > "$ANDROID_HOME/licenses/android-googletv-license" 2>/dev/null << 'EOF'
601085b53c84555a2897545eb1f38b296baeb1b5
EOF
    
    # 尝试设置权限（忽略权限错误）
    chmod 644 "$ANDROID_HOME/licenses"/* 2>/dev/null || true
    
    echo "已创建许可证文件："
    ls -la "$ANDROID_HOME/licenses/" 2>/dev/null || echo "无法列出许可证文件"
else
    echo "❌ 无法创建许可证目录，使用用户目录备用方案"
    
    # 备用方案：创建用户级别的许可证
    USER_LICENSE_DIR="$HOME/.android/licenses"
    mkdir -p "$USER_LICENSE_DIR"
    
    cat > "$USER_LICENSE_DIR/android-sdk-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c55d
EOF
    
    cat > "$USER_LICENSE_DIR/android-googletv-license" << 'EOF'
601085b53c84555a2897545eb1f38b296baeb1b5
EOF
    
    cat > "$USER_LICENSE_DIR/android-sdk-preview-license" << 'EOF'
d56f5187479451eabf01fb78af6dfcb131a6481e
EOF
    
    cat > "$USER_LICENSE_DIR/google-gdk" << 'EOF'
84831b9409646a918e30573bab4c9c91346b8b90
EOF
    
    chmod 644 "$USER_LICENSE_DIR"/* 2>/dev/null || true
    
    echo "用户许可证文件创建完成："
    ls -la "$USER_LICENSE_DIR/" 2>/dev/null || echo "无法列出用户许可证文件"
fi

# 方法2: 使用 expect（如果许可证文件无效）
echo "=== 方法2: 使用 expect ==="
if command -v expect &> /dev/null; then
    echo "使用 expect 自动确认..."
    timeout 60 expect -c "
    log_user 1
    spawn $SDKMANAGER --licenses
    expect {
        \"y/N?\" { send \"y\r\"; exp_continue }
        \"(y/N)\" { send \"y\r\"; exp_continue }
        \"Accept? (y/N)\" { send \"y\r\"; exp_continue }
        \"Review licenses that have not been accepted\" { send \"y\r\"; exp_continue }
        \"License android-googletv-license\" { send \"y\r\"; exp_continue }
        timeout { exit 0 }
        eof { exit 0 }
    }
    " 2>/dev/null || echo "expect 超时或失败，但许可证文件已创建"
fi

# 方法3: 使用 printf（备用方案）
echo "=== 方法3: 使用 printf ==="
timeout 120 bash -c "
    for i in {1..50}; do
        echo 'y'
        sleep 0.1
    done
" | "$SDKMANAGER" --licenses 2>/dev/null || echo "printf 方法完成（许可证文件已创建）"

# 方法4: 使用 yes（最终备用方案）
echo "=== 方法4: 使用 yes ==="
timeout 120 yes | "$SDKMANAGER" --licenses 2>/dev/null || echo "yes 方法完成（许可证文件已创建）"

# 验证结果
echo "=== 验证许可证状态 ==="
ls -la "$ANDROID_HOME/licenses/" 2>/dev/null || echo "许可证目录不存在"

# 再次确认许可证文件存在且有效
echo "确认关键许可证文件："
for license_file in "android-sdk-license" "android-googletv-license"; do
    if [ -f "$ANDROID_HOME/licenses/$license_file" ]; then
        echo "✅ $license_file 存在"
    else
        echo "❌ $license_file 缺失"
    fi
done

echo "已安装的组件："
"$SDKMANAGER" --list_installed 2>/dev/null | head -5 || echo "无法列出已安装组件"

echo "=== 许可证强制处理完成 ==="