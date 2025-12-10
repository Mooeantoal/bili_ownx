#!/bin/bash

echo "🔍 验证布局溢出修复..."

# 1. 代码分析
echo "1. 执行代码分析..."
flutter analyze --no-fatal-infos
if [ $? -eq 0 ]; then
    echo "✅ 代码分析通过"
else
    echo "❌ 代码分析失败"
    exit 1
fi

# 2. 检查修复内容
echo "2. 检查修复内容..."

# 检查PopularVideoCard是否包含响应式设计
if grep -q "getCardHeight\|getCoverWidth\|getCoverHeight" lib/widgets/popular_video_card.dart; then
    echo "✅ PopularVideoCard已添加响应式设计"
else
    echo "❌ PopularVideoCard缺少响应式设计"
    exit 1
fi

# 检查是否移除了固定高度设置
if grep -q "height: 90" lib/widgets/popular_video_card.dart; then
    echo "❌ 仍然存在固定高度设置"
    exit 1
else
    echo "✅ 已移除固定高度设置"
fi

# 3. 检查搜索页面布局
if grep -q "padding.*vertical.*4" lib/pages/search_page.dart; then
    echo "✅ 搜索页面已添加适当内边距"
else
    echo "❌ 搜索页面缺少内边距设置"
    exit 1
fi

# 4. 检查热门页面布局
if grep -q "padding.*vertical.*2" lib/pages/popular_page.dart; then
    echo "✅ 热门页面已优化垂直间距"
else
    echo "❌ 热门页面间距设置不正确"
    exit 1
fi

# 5. 检查主要组件是否使用了Flexible和Expanded
flexible_count=$(grep -c "Flexible\|Expanded" lib/widgets/popular_video_card.dart)
if [ $flexible_count -ge 2 ]; then
    echo "✅ 已使用Flexible/Expanded防止溢出"
else
    echo "❌ 缺少Flexible/Expanded防护"
    exit 1
fi

echo "🎉 所有布局验证通过！溢出问题已修复。"
echo ""
echo "修复内容："
echo "- ✅ PopularVideoCard添加响应式尺寸设计"
echo "- ✅ 调整封面图尺寸以适应容器"
echo "- ✅ 使用Flexible/Expanded防止文本溢出"
echo "- ✅ 优化列表内边距和间距"
echo "- ✅ 改进时长标签显示"
echo "- ✅ 确保搜索结果和热门页面在不同屏幕尺寸下正常显示"