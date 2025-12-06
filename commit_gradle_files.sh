#!/bin/bash

echo "=== 提交 Gradle Wrapper 文件 ==="

# 确保 .gitignore 允许 gradle 文件
sed -i 's/^\/gradlew/#\/gradlew/' android/.gitignore
sed -i 's/^\/gradlew\.bat/#\/gradlew\.bat/' android/.gitignore

# 添加文件到 git
git add android/gradlew
git add android/gradlew.bat
git add android/.gitignore

# 提交更改
git commit -m "修复：添加 Gradle Wrapper 文件到仓库，修复 CI 构建"

echo "=== Gradle Wrapper 文件已提交 ==="
echo "现在 GitHub Actions 应该可以找到 gradlew 文件了"