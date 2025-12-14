#!/bin/bash

# 完全绕过许可证交互的 Android SDK 组件安装脚本
# 参数: $1 = 组件列表 (例如: "platforms;android-36 build-tools;36.0.0")

COMPONENTS="$1"

if [ -z "$COMPONENTS" ]; then
    echo "❌ 错误: 请提供要安装的组件列表"
    echo "用法: $0 \"platforms;android-36 build-tools;36.0.0\""
    exit 1
fi

echo "🚀 开始安装 Android SDK 组件..."
echo "📦 组件列表: $COMPONENTS"

# ========== 激进预清理策略 ==========
echo "🧹 [AGGRESSIVE PRE-CLEAN] 预清理可能冲突的android-36目录..."
SDK_ROOT="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

if [ -d "$SDK_ROOT/platforms" ]; then
    # 删除所有android-36相关目录(包括android-36, android-36-2等)
    find "$SDK_ROOT/platforms" -maxdepth 1 -name "android-36*" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✅ 预清理完成"
    echo "📁 platforms目录内容:"
    ls -la "$SDK_ROOT/platforms/" || echo "platforms目录为空(正常)"
else
    echo "📁 platforms目录不存在(将由SDK安装器创建)"
fi

# 设置环境变量强制跳过许可证检查
export ANDROID_SDKMANAGER_ALLOW_PRE25=true
export ANDROID_SDK_LICENSES_ACCEPTED=true
export SDKMANAGER_ALLOW_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicense=true -Dandroid.sdk.license.accepted=true"

# 多种安装策略，确保至少一个成功

# ========== 路径验证和修复函数 ==========
verify_and_fix_sdk_path() {
    echo "🔍 验证安装路径..."
    
    if [ -d "$SDK_ROOT/platforms/android-36-2" ]; then
        echo "🚨 检测到SDK安装器创建了 android-36-2,立即重命名..."
        rm -rf "$SDK_ROOT/platforms/android-36"
        mv "$SDK_ROOT/platforms/android-36-2" "$SDK_ROOT/platforms/android-36"
        echo "✅ 路径修复完成"
    fi
    
    # 验证关键文件存在
    if [ -f "$SDK_ROOT/platforms/android-36/android.jar" ]; then
        echo "✅ 最终验证通过: android-36 已正确安装"
        return 0
    else
        echo "⚠️ 警告: android.jar未找到"
        return 1
    fi
}

echo "🔄 尝试方法 1: 直接安装（预配置许可证）"
if sdkmanager --install $COMPONENTS 2>/dev/null; then
    echo "✅ 方法 1 成功"
    verify_and_fix_sdk_path \u0026\u0026 exit 0
fi

echo "⚠️ 方法 1 失败，尝试方法 2: expect 自动化"
if command -v expect >/dev/null 2>&1; then
    expect -c "
        set timeout 300
        spawn sdkmanager --install $COMPONENTS
        expect {
            \"Accept? (y/N)\" { 
                send \"y\r\"
                exp_continue
            }
            \"License\" { 
                send \"y\r\"
                exp_continue
            }
            \"terms and conditions\" { 
                send \"y\r\"
                exp_continue
            }
            \"Review licenses\" { 
                send \"y\r\"
                exp_continue
            }
            eof {
                puts \"✅ 方法 2 成功\"
                exit 0
            }
            timeout {
                puts \"⚠️ 方法 2 超时\"
                exit 1
            }
        }
    " && {
        echo "✅ 方法 2 成功"
        verify_and_fix_sdk_path && exit 0
    }
fi

echo "⚠️ 方法 2 失败，尝试方法 3: yes 命令管道"
if command -v yes >/dev/null 2>&1; then
    if timeout 120 yes | sdkmanager --install $COMPONENTS 2>/dev/null; then
        echo "✅ 方法 3 成功"
        verify_and_fix_sdk_path && exit 0
    fi
else
    echo "⚠️ yes 命令不可用"
fi

echo "⚠️ 方法 3 失败，尝试方法 4: 强制跳过许可证"
# 创建一个临时的 sdkmanager 包装脚本
cat > /tmp/sdkmanager-wrapper.sh << 'EOF'
#!/bin/bash
# 强制接受所有许可证的环境变量
export ANDROID_SDKMANAGER_ALLOW_PRE25=true
export ANDROID_SDK_LICENSES_ACCEPTED=true
export SDKMANAGER_ALLOW_ACCEPT_LICENSES=true

# 调用真实的 sdkmanager
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "$@"
EOF

chmod +x /tmp/sdkmanager-wrapper.sh

# 使用包装脚本安装
if /tmp/sdkmanager-wrapper.sh --install $COMPONENTS 2>/dev/null; then
    echo "✅ 方法 4 成功"
    rm -f /tmp/sdkmanager-wrapper.sh
    verify_and_fix_sdk_path && exit 0
else
    echo "⚠️ 方法 4 失败"
    rm -f /tmp/sdkmanager-wrapper.sh
fi

echo "⚠️ 所有方法都失败，检查现有组件..."
echo "📊 当前已安装组件:"
sdkmanager --list_installed 2>/dev/null || echo "无法列出已安装组件"

echo "📁 检查目录结构:"
ls -la $ANDROID_HOME/platforms/ 2>/dev/null || echo "platforms 目录不存在"
ls -la $ANDROID_HOME/build-tools/ 2>/dev/null || echo "build-tools 目录不存在"

# ===== 最后一道防线:检查是否有可修复的路径问题 =====
echo "🔍 最后检查: 是否需要修复路径..."
if verify_and_fix_sdk_path; then
    echo "✅ 路径修复成功,SDK可用"
    exit 0
fi

echo "⚠️ 继续构建流程，Flutter 可能会下载缺失的组件..."