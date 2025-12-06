#!/bin/bash

# 完全避免权限问题的许可证处理脚本
# 只使用用户可写目录

echo "=== 用户目录许可证处理脚本 ==="

# 检查环境
if [ -z "$ANDROID_HOME" ]; then
    echo "错误: ANDROID_HOME 未设置"
    exit 1
fi

# 设置关键环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.accept licenses=true -Dandroid.licenses.accepted=true"

# 只使用用户目录
USER_LICENSE_DIR="$HOME/.android/licenses"
echo "创建用户许可证目录: $USER_LICENSE_DIR"
mkdir -p "$USER_LICENSE_DIR"

# 创建所有必要的许可证文件
echo "创建用户许可证文件..."

# Android SDK License
cat > "$USER_LICENSE_DIR/android-sdk-license" << 'EOF'
8933bad161af4178b1185d1a37fbf41ea5269c55d
EOF

# Google TV License (问题所在)
cat > "$USER_LICENSE_DIR/android-googletv-license" << 'EOF'
601085b53c84555a2897545eb1f38b296baeb1b5
EOF

# Preview License
cat > "$USER_LICENSE_DIR/android-sdk-preview-license" << 'EOF'
d56f5187479451eabf01fb78af6dfcb131a6481e
EOF

# Google GDK License
cat > "$USER_LICENSE_DIR/google-gdk" << 'EOF'
84831b9409646a918e30573bab4c9c91346b8b90
EOF

# Google License
cat > "$USER_LICENSE_DIR/android-sdk-google-license" << 'EOF'
598de3781d13c8c5df5a678110464d3863734768
EOF

# ARM DBT License
cat > "$USER_LICENSE_DIR/android-sdk-arm-dbt-license" << 'EOF'
24333f8a63b6825ea9c5514e83c0e9a993a0a6f
EOF

# Intel Extra License
cat > "$USER_LICENSE_DIR/intel-android-extra-license" << 'EOF'
33b6a2b64607111b2893360c6b44c7a64512267
EOF

# MIPS Extra License
cat > "$USER_LICENSE_DIR/mips-android-extra-license" << 'EOF'
84831b9409646a918e30573bab4c9c91346b8b90
EOF

# 设置权限
chmod 644 "$USER_LICENSE_DIR"/*

# 设置用户许可证路径为 Android SDK 许可证路径
export ANDROID_SDK_LICENSE_PATH="$USER_LICENSE_DIR"

echo "用户许可证文件创建完成："
ls -la "$USER_LICENSE_DIR/"

# 验证许可证
echo "验证许可证状态..."
for license_file in "android-sdk-license" "android-googletv-license" "android-sdk-preview-license" "google-gdk"; do
    if [ -f "$USER_LICENSE_DIR/$license_file" ]; then
        echo "✅ $license_file: 已创建"
    else
        echo "❌ $license_file: 缺失"
    fi
done

# 设置构建环境
echo "设置构建环境变量..."
export ANDROID_SDK_ACCEPT_LICENSES=true
export ACCEPT_LICENSES=true
export GRADLE_OPTS="-Dandroid.accept licenses=true -Dandroid.licenses.accepted=true"

echo "=== 用户许可证处理完成 ==="
echo "现在可以安全运行构建命令"
echo "推荐命令:"
echo "flutter clean"
echo "flutter pub get"
echo "flutter build apk --debug"