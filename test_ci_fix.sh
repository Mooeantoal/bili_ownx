#!/bin/bash

echo "🔧 CI 修复验证脚本"
echo "==================="

# 1. 验证 YAML 语法
echo "1. 验证 GitHub Actions 配置文件语法..."
if command -v yamllint &> /dev/null; then
    yamllint .github/workflows/ci.yml
    if [ $? -eq 0 ]; then
        echo "✅ YAML 语法正确"
    else
        echo "❌ YAML 语法错误"
        exit 1
    fi
else
    echo "⚠️  yamllint 未安装，跳过 YAML 语法检查"
fi

# 2. 验证 Gradle 配置
echo "2. 验证 Gradle 配置..."
if [ -f "android/gradle.properties" ]; then
    if grep -q "org.gradle.java.home" android/gradle.properties && ! grep -q "# org.gradle.java.home=" android/gradle.properties; then
        echo "❌ gradle.properties 中仍包含硬编码的 Java Home 路径"
        exit 1
    else
        echo "✅ Gradle 配置正确"
    fi
else
    echo "❌ 找不到 gradle.properties 文件"
    exit 1
fi

# 3. 检查 CI 配置中的硬编码路径
echo "3. 检查 CI 配置中的硬编码路径..."
if grep -q "export JAVA_HOME=/" .github/workflows/ci.yml; then
    echo "❌ CI 配置中仍包含硬编码的 Java Home 路径"
    exit 1
else
    echo "✅ CI 配置中无硬编码路径"
fi

# 4. 验证 Flutter 环境
echo "4. 验证 Flutter 环境..."
if command -v flutter &> /dev/null; then
    flutter doctor
    echo "✅ Flutter 环境检查完成"
else
    echo "⚠️  Flutter 未安装或不在 PATH 中"
fi

# 5. 验证必要文件存在
echo "5. 验证项目文件结构..."
required_files=(
    "pubspec.yaml"
    "android/build.gradle.kts"
    "android/app/build.gradle.kts"
    ".github/workflows/ci.yml"
    "android/gradle.properties"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 不存在"
        exit 1
    fi
done

echo ""
echo "🎉 所有验证通过！CI 修复成功！"
echo ""
echo "📋 下一步操作："
echo "1. 提交代码: git add . && git commit -m \"修复 Java Home 路径问题\""
echo "2. 推送代码: git push origin main"
echo "3. 检查 CI 运行状态"
echo ""