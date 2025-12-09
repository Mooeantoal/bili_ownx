import 'package:flutter/material.dart';
import '../widgets/improved_video_card.dart';
import '../models/search_result.dart';
import '../pages/search_page.dart';

/// 搜索结果演示页面 - 用于对比新旧卡片效果
class SearchDemoPage extends StatefulWidget {
  const SearchDemoPage({super.key});

  @override
  State<SearchDemoPage> createState() => _SearchDemoPageState();
}

class _SearchDemoPageState extends State<SearchDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索结果卡片对比'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 新版卡片展示
            _buildSectionHeader('新版卡片（改进后）'),
            ..._demoVideos.map((video) => ImprovedVideoCard(
              video: video,
              heroTag: 'demo_${video.bvid}',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('点击了: ${video.title}')),
                );
              },
              onCommentTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('查看评论: ${video.title}')),
                );
              },
            )),
            
            const SizedBox(height: 20),
            
            // 功能说明
            _buildSectionHeader('改进说明'),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✨ 信息密度提升', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('• 显示播放量、弹幕数、评论数'),
                      Text('• 添加发布时间信息'),
                      Text('• 保留视频ID标识'),
                      SizedBox(height: 16),
                      
                      Text('🎨 视觉效果优化', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('• 圆角封面设计'),
                      Text('• Hero动画支持'),
                      Text('• 时长标签显示在封面上'),
                      Text('• 缓存图片加载'),
                      SizedBox(height: 16),
                      
                      Text('🔧 功能增强', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('• 右侧操作按钮（评论、更多）'),
                      Text('• 支持复制链接和分享'),
                      Text('• 响应式布局设计'),
                      Text('• 更好的错误处理'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 演示视频数据
  List<VideoSearchResult> get _demoVideos => [
    VideoSearchResult(
      title: '【官方MV】new boy - 房东的猫，陪你从1999唱到2024',
      cover: 'https://i2.hdslb.com/bfs/archive/b7c6b8e9c3e5d4a8f9a3b2c1d6e5f4a3b2c1d6e5.jpg',
      author: '房东的猫',
      play: 1250000,
      duration: '4:32',
      bvid: 'BV1uH4y1A7J8',
      aid: 987654321,
      danmaku: 8560,
      like: 45000,
      coin: 2300,
      favorite: 12000,
      reply: 890,
      pubdate: DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      description: '来自1999年的新男孩，穿越时空的温暖歌声',
      mid: '123456789',
    ),
    VideoSearchResult(
      title: '【技术分享】Flutter开发技巧：如何构建高性能的应用界面',
      cover: 'https://i1.hdslb.com/bfs/archive/c8d7a9f2e4b5d3a9f4b2c1d6e5f4a3b2c1d6e5.jpg',
      author: 'Flutter开发者',
      play: 85000,
      duration: '12:18',
      bvid: 'BV2fH4y1A7K9',
      aid: 876543210,
      danmaku: 2340,
      like: 3200,
      coin: 450,
      favorite: 890,
      reply: 156,
      pubdate: DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000,
      description: '深入探讨Flutter性能优化的各种技巧和最佳实践',
      mid: '987654321',
    ),
    VideoSearchResult(
      title: '【美食制作】超详细的麻婆豆腐做法，正宗川菜教程',
      cover: 'https://i3.hdslb.com/bfs/archive/d9e8b0f3c5e6d4a9f5b2c1d6e5f4a3b2c1d6e5.jpg',
      author: '川菜大师',
      play: 320000,
      duration: '8:45',
      bvid: 'BV3gH4y1A7L0',
      aid: 765432109,
      danmaku: 5600,
      like: 15000,
      coin: 890,
      favorite: 3400,
      reply: 234,
      pubdate: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
      description: '手把手教你做出正宗的麻婆豆腐，麻辣鲜香',
      mid: '456789123',
    ),
  ];
}