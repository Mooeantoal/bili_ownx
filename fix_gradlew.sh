#!/bin/bash

echo "=== 修复 gradlew 权限问题 ==="

cd android

echo "=== 检查 gradlew 文件 ==="
ls -la gradlew

echo "=== 添加执行权限 ==="
chmod +x gradlew

echo "=== 再次检查权限 ==="
ls -la gradlew

echo "=== 测试 gradlew 是否可用 ==="
./gradlew --version

echo "=== 尝试构建 ==="
./gradlew assembleDebug