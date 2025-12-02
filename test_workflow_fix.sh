#!/bin/bash

echo "测试 GitHub Actions 工作流修复"
echo "================================"

echo "1. 检查工作流文件语法："
if command -v yamllint &> /dev/null; then
    yamllint .github/workflows/build.yml
else
    echo "yamllint 未安装，跳过语法检查"
fi

echo ""
echo "2. 验证工作流配置："
echo "- 检查无效参数 'continue-on-error' 是否已移除"
if grep -q "continue-on-error: true" .github/workflows/build.yml; then
    echo "❌ 仍然包含无效参数 'continue-on-error'"
else
    echo "✅ 已移除无效参数 'continue-on-error'"
fi

echo "- 检查是否使用了正确的 'if-no-files-found' 参数"
if grep -q "if-no-files-found: warn" .github/workflows/build.yml; then
    echo "✅ 使用了正确的 'if-no-files-found' 参数"
else
    echo "❌ 缺少正确的 'if-no-files-found' 参数"
fi

echo "- 检查 APK 文件路径是否包含 ABI 拆分目录"
if grep -q "android/app/build/outputs/apk/debug/**/*.apk" .github/workflows/build.yml; then
    echo "✅ 包含了 ABI 拆分目录路径"
else
    echo "❌ 缺少 ABI 拆分目录路径"
fi

echo ""
echo "3. 显示当前工作流的关键配置："
echo "Artifact 上传配置："
grep -A 10 "上传 APK 为 Artifact" .github/workflows/build.yml | grep -E "(name:|path:|if-no-files-found:|retention-days:)"

echo ""
echo "Release 配置："
grep -A 5 "创建 Release" .github/workflows/build.yml | grep -E "(tag_name:|files:)"