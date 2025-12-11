#!/bin/bash

# 完全绕过 Android SDK 许可证交互的脚本
# 参数: $1 = SDK_PATH

SDK_PATH="$1"
if [ -z "$SDK_PATH" ]; then
    SDK_PATH="$PWD/android-sdk"
fi

echo "🔧 配置 Android SDK 许可证绕过机制..."
echo "SDK 路径: $SDK_PATH"

# 创建许可证目录
mkdir -p "$SDK_PATH/licenses"
mkdir -p ~/.android

# 创建所有可能的许可证文件
cat > "$SDK_PATH/licenses/android-sdk-license" << 'EOF'
24333f8a63b6825ea9c55141383a0746b3326
EOF

cat > "$SDK_PATH/licenses/android-sdk-preview" << 'EOF'
84831b9409646a918e30573bab4c9d966a64d
EOF

cat > "$SDK_PATH/licenses/android-sdk-build-tools-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c
EOF

cat > "$SDK_PATH/licenses/android-sdk-platform-tools-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c
EOF

cat > "$SDK_PATH/licenses/google-android-play-auth-license" << 'EOF'
8f4ff02255e750b71392994d1d649be0b947ad1
EOF

cat > "$SDK_PATH/licenses/google-android-play-location-license" << 'EOF'
859f317ff2ccae9e4e47567d3db0f379c8c2f3e
EOF

cat > "$SDK_PATH/licenses/android-sdk-androidxr-license" << 'EOF'
d975f751698a77b6691ed5e903457d56aeac7c
EOF

cat > "$SDK_PATH/licenses/android-googletv-license" << 'EOF'
601085b94cd77d045dc5891f2b9bffa8a385
EOF

cat > "$SDK_PATH/licenses/google-gdk-license" << 'EOF'
569b3a84c4a29162dd4a4285954c3e60463b2b
EOF

cat > "$SDK_PATH/licenses/google-sdk-license" << 'EOF'
84831b9409646a918e30573bab4c9d966a64d
EOF

cat > "$SDK_PATH/licenses/m2repository-license" << 'EOF'
24333f8a63b6825ea9c55141383a0746b3326
EOF

cat > "$SDK_PATH/licenses/google-adt-license" << 'EOF'
84831b9409646a918e30573bab4c9d966a64d
EOF

# 创建全局配置
cat > ~/.android/repositories.cfg << 'EOF'
### User Settings for Android SDK
count=0
EOF

cat > "$SDK_PATH/repositories.cfg" << 'EOF'
### User Settings for Android SDK
count=0
EOF

# 设置权限
chmod 644 "$SDK_PATH/licenses"/* 2>/dev/null || true

# 导出环境变量
export ANDROID_SDKMANAGER_ALLOW_PRE25=true
export ANDROID_SDK_LICENSES_ACCEPTED=true
export SDKMANAGER_ALLOW_ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.acceptLicense=true -Dandroid.sdk.license.accepted=true"

# 写入到 GITHUB_ENV（如果存在）
if [ -n "$GITHUB_ENV" ]; then
    echo "ANDROID_SDKMANAGER_ALLOW_PRE25=true" >> "$GITHUB_ENV"
    echo "ANDROID_SDK_LICENSES_ACCEPTED=true" >> "$GITHUB_ENV"
    echo "SDKMANAGER_ALLOW_ACCEPT_LICENSES=true" >> "$GITHUB_ENV"
    echo "GRADLE_OPTS=-Dandroid.acceptLicense=true -Dandroid.sdk.license.accepted=true" >> "$GITHUB_ENV"
fi

echo "✅ Android SDK 许可证绕过配置完成！"
echo "📁 许可证文件数量: $(ls -1 "$SDK_PATH/licenses" | wc -l)"
echo "🔍 许可证文件列表:"
ls -la "$SDK_PATH/licenses/" || echo "无法列出许可证文件"