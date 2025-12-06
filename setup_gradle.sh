#!/bin/bash

echo "=== 设置 Gradle Wrapper ==="

cd android

echo "=== 检查 Gradle Wrapper 文件 ==="
if [ ! -f "gradlew" ]; then
    echo "gradlew 不存在，生成 Gradle Wrapper..."
    
    # 确保有 Gradle
    if ! command -v gradle &> /dev/null; then
        echo "安装 Gradle..."
        # 使用 SDKMAN 或直接下载
        wget https://services.gradle.org/distributions/gradle-8.7-bin.zip
        unzip gradle-8.7-bin.zip
        export PATH=$PWD/gradle-8.7/bin:$PATH
    fi
    
    # 生成 Gradle Wrapper
    gradle wrapper --gradle-version 8.7
    
    # 设置执行权限
    chmod +x gradlew
    chmod +x gradlew.bat
else
    echo "gradlew 存在，设置权限..."
    chmod +x gradlew
fi

echo "=== 验证 Gradle Wrapper ==="
./gradlew --version

echo "=== Gradle Wrapper 设置完成 ==="