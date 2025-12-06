#!/bin/bash

echo "=== 修复依赖版本冲突 ==="

# 方案1: 升级SDK约束（如果Flutter版本支持）
echo "检查当前Flutter版本..."
flutter --version

echo ""
echo "=== 方案选择 ==="
echo "1. 升级SDK约束到 >=3.4.0 (推荐)"
echo "2. 降级shared_preferences到2.2.3"
echo "3. 两者都尝试"
echo ""
read -p "请选择方案 (1-3): " choice

case $choice in
  1)
    echo "=== 升级SDK约束 ==="
    sed -i "s/sdk: '>=3.3.0 <4.0.0'/sdk: '>=3.4.0 <4.0.0'/" pubspec.yaml
    echo "已升级SDK约束到 >=3.4.0"
    ;;
  2)
    echo "=== 降级shared_preferences ==="
    sed -i 's/shared_preferences: ^2.3.2/shared_preferences: ^2.2.3/' pubspec.yaml
    echo "已降级shared_preferences到2.2.3"
    ;;
  3)
    echo "=== 同时应用两种修复 ==="
    sed -i "s/sdk: '>=3.3.0 <4.0.0'/sdk: '>=3.4.0 <4.0.0'/" pubspec.yaml
    sed -i 's/shared_preferences: ^2.3.2/shared_preferences: ^2.2.3/' pubspec.yaml
    echo "已同时升级SDK约束并降级shared_preferences"
    ;;
  *)
    echo "无效选择，退出"
    exit 1
    ;;
esac

echo ""
echo "=== 清理并重新获取依赖 ==="
flutter clean
flutter pub get

echo ""
echo "=== 验证修复结果 ==="
flutter doctor --verbose
echo ""
echo "=== 如果仍有问题，请检查Flutter版本是否支持Dart 3.4.0+ ==="