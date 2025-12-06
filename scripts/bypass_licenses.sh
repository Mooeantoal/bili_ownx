#!/bin/bash

# 许可证绕过脚本 - 专门用于 CI 环境
# 直接创建所有必需的许可证文件，完全避免交互

echo "=== 许可证绕过脚本 ==="

# 设置环境变量
export ANDROID_SDK_ACCEPT_LICENSES=true
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ACCEPT_LICENSES=true

# 确保目录存在
mkdir -p "$ANDROID_HOME/licenses"

# 创建完整的许可证集合
declare -A LICENSES=(
    ["android-sdk-license"]="8933bad161af4178b1185d1a37fbf41ea5269c55d"
    ["android-sdk-preview-license"]="d56f5187479451eabf01fb78af6dfcb131a6481e"
    ["android-googletv-license"]="601085b53c84555a2897545eb1f38b296baeb1b5"
    ["google-gdk"]="84831b9409646a918e30573bab4c9c91346b8b90"
    ["android-sdk-google-license"]="598de3781d13c8c5df5a678110464d3863734768"
    ["android-sdk-arm-dbt-license"]="24333f8a63b6825ea9c5514e83c0e9a993a0a6f"
    ["intel-android-extra-license"]="33b6a2b64607111b2893360c6b44c7a64512267"
    ["mips-android-extra-license"]="84831b9409646a918e30573bab4c9c91346b8b90"
)

echo "创建许可证文件..."
for license_file in "${!LICENSES[@]}"; do
    echo "${LICENSES[$license_file]}" > "$ANDROID_HOME/licenses/$license_file"
    echo "✅ 创建: $license_file"
done

# 设置权限
chmod 644 "$ANDROID_HOME/licenses"/*

echo "许可证目录内容："
ls -la "$ANDROID_HOME/licenses/"

# 验证关键许可证
echo "验证许可证完整性..."
if [ -f "$ANDROID_HOME/licenses/android-googletv-license" ]; then
    echo "✅ Google TV 许可证已创建"
else
    echo "❌ Google TV 许可证创建失败"
fi

echo "=== 许可证绕过完成 ==="