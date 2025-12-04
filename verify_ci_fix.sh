#!/bin/bash

# CI/CD 修复验证脚本
# 用于验证 GitHub Actions 配置修复是否成功

echo "=========================================="
echo "CI/CD 修复验证脚本"
echo "=========================================="
echo

# 1. 检查 GitHub Actions 配置
echo "1. 检查 GitHub Actions 配置..."
if [ -f ".github/workflows/ci.yml" ]; then
    echo "✅ CI 配置文件存在"
    
    # 检查 Flutter Action 版本
    if grep -q "subosito/flutter-action@v3" .github/workflows/ci.yml; then
        echo "✅ Flutter Action 版本已更新为 v3"
    else
        echo "❌ Flutter Action 版本未正确更新"
    fi
    
    # 检查 Java Home 设置
    if grep -q "export JAVA_HOME=/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.17-10/x64" .github/workflows/ci.yml; then
        echo "✅ Java Home 路径已修复"
    else
        echo "❌ Java Home 路径未修复"
    fi
else
    echo "❌ CI 配置文件不存在"
fi

echo

# 2. 检查本地 Flutter 环境
echo "2. 检查本地 Flutter 环境..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter 已安装"
    flutter --version
else
    echo "❌ Flutter 未安装或不在 PATH 中"
fi

echo

# 3. 检查 Java 环境
echo "3. 检查 Java 环境..."
if command -v java &> /dev/null; then
    echo "✅ Java 已安装"
    java -version
else
    echo "❌ Java 未安装或不在 PATH 中"
fi

echo

# 4. 检查 Gradle 配置
echo "4. 检查 Gradle 配置..."
if [ -f "android/gradlew" ]; then
    echo "✅ Gradle Wrapper 存在"
    
    # 检查 Gradle 版本
    if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
        echo "✅ Gradle Wrapper 配置存在"
    else
        echo "❌ Gradle Wrapper 配置缺失"
    fi
else
    echo "❌ Gradle Wrapper 不存在"
fi

echo

# 5. 检查项目依赖
echo "5. 检查项目依赖..."
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml 存在"
    
    # 运行依赖检查
    if command -v flutter &> /dev/null; then
        echo "检查依赖兼容性..."
        flutter pub get
        if [ $? -eq 0 ]; then
            echo "✅ 依赖解析成功"
        else
            echo "❌ 依赖解析失败"
        fi
    fi
else
    echo "❌ pubspec.yaml 不存在"
fi

echo

# 6. 模拟构建测试
echo "6. 模拟构建测试..."
if command -v flutter &> /dev/null && [ -f "pubspec.yaml" ]; then
    echo "尝试清理项目..."
    flutter clean
    
    if [ $? -eq 0 ]; then
        echo "✅ 项目清理成功"
    else
        echo "❌ 项目清理失败"
    fi
    
    echo "尝试获取依赖..."
    flutter pub get
    
    if [ $? -eq 0 ]; then
        echo "✅ 依赖获取成功"
    else
        echo "❌ 依赖获取失败"
    fi
else
    echo "❌ 无法进行构建测试（Flutter 或项目配置问题）"
fi

echo
echo "=========================================="
echo "验证完成"
echo "=========================================="
echo
echo "如果所有检查都显示 ✅，说明修复成功，可以推送代码触发 CI/CD。"
echo "如果有 ❌ 项目，请先修复本地问题再推送。"
echo

# 7. 提供推送建议
echo "推送建议："
echo "git add .github/workflows/ci.yml"
echo "git commit -m \"修复 Java Home 路径和 Flutter Action 版本问题\""
echo "git push origin main"
echo