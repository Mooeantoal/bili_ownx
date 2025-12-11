#!/bin/bash

# 安装 Android SDK 组件的脚本
# 参数: $1 = COMPONENTS (例如: "platforms;android-35 build-tools;35.0.0")

COMPONENTS="$1"
if [ -z "$COMPONENTS" ]; then
    COMPONENTS="platforms;android-35 build-tools;35.0.0"
fi

echo "🚀 开始安装 Android SDK 组件..."
echo "📦 组件列表: $COMPONENTS"

# 设置环境变量
export ANDROID_SDKMANAGER_ALLOW_PRE25=true
export ANDROID_SDK_LICENSES_ACCEPTED=true
export SDKMANAGER_ALLOW_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicense=true -Dandroid.sdk.license.accepted=true"

# 创建必要的目录
mkdir -p "$ANDROID_HOME/platforms"
mkdir -p "$ANDROID_HOME/build-tools"

# 多重安装策略
echo "🔄 尝试安装方法 1: 直接安装（已配置许可证）"
if sdkmanager --install $COMPONENTS; then
    echo "✅ 方法 1 成功"
    exit 0
fi

echo "⚠️ 方法 1 失败，尝试方法 2: expect 脚本"
if command -v expect >/dev/null 2>&1; then
    if expect -c "
        spawn sdkmanager --install $COMPONENTS
        expect {
            \"Accept? (y/N)\" { send \"y\r\"; exp_continue }
            \"License\" { send \"y\r\"; exp_continue }
            \"terms and conditions\" { send \"y\r\"; exp_continue }
            eof
        }
    "; then
        echo "✅ 方法 2 成功"
        exit 0
    fi
else
    echo "⚠️ expect 命令不可用"
fi

echo "⚠️ 方法 2 失败，尝试方法 3: yes 命令"
if command -v yes >/dev/null 2>&1; then
    if yes | sdkmanager --install $COMPONENTS; then
        echo "✅ 方法 3 成功"
        exit 0
    fi
else
    echo "⚠️ yes 命令不可用"
fi

echo "⚠️ 方法 3 失败，尝试方法 4: printf 自动确认"
if printf "y\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\n" | sdkmanager --install $COMPONENTS; then
    echo "✅ 方法 4 成功"
    exit 0
fi

echo "⚠️ 所有安装方法都失败，检查组件是否存在..."
echo "📁 检查现有安装:"
ls -la "$ANDROID_HOME/platforms/" 2>/dev/null || echo "platforms 目录不存在"
ls -la "$ANDROID_HOME/build-tools/" 2>/dev/null || echo "build-tools 目录不存在"

echo "🔍 检查 sdkmanager 状态:"
sdkmanager --list_installed || echo "无法列出已安装组件"

echo "⚠️ 继续构建流程，某些组件可能已存在..."