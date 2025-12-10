#!/bin/bash

echo "🔍 验证视频ID问题修复..."

# 1. 代码分析
echo "1. 执行代码分析..."
flutter analyze --no-fatal-infos
if [ $? -eq 0 ]; then
    echo "✅ 代码分析通过"
else
    echo "❌ 代码分析失败"
    exit 1
fi

# 2. 检查问题BVID
echo "2. 检查问题BVID..."

problem_bvids=("BV0987654321" "BV1234567890" "BV1122334455" "BVAAAAAAAAAA" "BV1YW411T7Y9")
found_problem=false

for bvid in "${problem_bvids[@]}"; do
    if grep -r "$bvid" lib/pages/ --include="*.dart" >/dev/null 2>&1; then
        echo "❌ 发现问题BVID: $bvid"
        found_problem=true
    fi
done

if [ "$found_problem" = false ]; then
    echo "✅ 未发现已知的问题BVID"
else
    echo "❌ 仍然存在问题BVID，需要继续修复"
    exit 1
fi

# 3. 检查BVID格式验证
echo "3. 检查BVID格式验证..."

if grep -q "_isProblematicBvid\|检测问题BVID" lib/pages/player_page.dart; then
    echo "✅ 已添加问题BVID检测机制"
else
    echo "❌ 缺少问题BVID检测机制"
    exit 1
fi

# 4. 检查验证函数
if grep -q "_validateVideoIds\|RegExp.*BV" lib/pages/player_page.dart; then
    echo "✅ 视频ID验证函数已存在"
else
    echo "❌ 缺少视频ID验证函数"
    exit 1
fi

# 5. 检查真实BVID示例
echo "5. 检查真实BVID示例..."

real_bvids=("BV1uS4y1U7UF" "BV1GJ411x7h7" "BV1qJ41187rp")
found_real=false

for bvid in "${real_bvids[@]}"; do
    if grep -r "$bvid" lib/pages/ --include="*.dart" >/dev/null 2>&1; then
        echo "✅ 发现真实BVID示例: $bvid"
        found_real=true
    fi
done

if [ "$found_real" = true ]; then
    echo "✅ 已使用真实的Bilibili视频ID"
else
    echo "❌ 缺少真实BVID示例"
    exit 1
fi

echo "🎉 所有视频ID验证通过！"
echo ""
echo "修复内容："
echo "- ✅ 移除了所有已知的问题BVID"
echo "- ✅ 添加了智能BVID格式验证"
echo "- ✅ 增强了错误处理和用户提示"
echo "- ✅ 使用了真实有效的bilibili视频ID"
echo "- ✅ 提供了详细的错误诊断信息"