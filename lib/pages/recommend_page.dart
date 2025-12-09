import 'package:flutter/material.dart';
import '../widgets/recommend_card.dart';
import '../models/bili_video_info.dart';
import '../player_page.dart';

/// 推荐页面 - 完全基于bili_you推荐页面设计
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<BiliVideoInfo> _recommendItems = [];
  bool _isLoading = false;
  
  int _heroTagId = 0;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecommendData();
  }

  Future<void> _loadRecommendData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟推荐数据
      await Future.delayed(const Duration(seconds: 1));
      
      final demoData = [
        BiliVideoInfo(
          bvid: 'BV1234567890',
          aid: '123456789',
          title: '【官方MV】new boy - 房东的猫，陪你从1999唱到2024，经典重现',
          author: '房东的猫',
          cover: 'https://i2.hdslb.com/bfs/archive/b7c6b8e9c3e5d4a8f9a3b2c1d6e5f4a3b2c1d6e5.jpg',
          duration: '4:32',
          play: 1250000,
          danmaku: 8560,
          pubdate: 1703520000,
          cid: 279786,
        ),
        BiliVideoInfo(
          bvid: 'BV0987654321',
          aid: '987654321',
          title: '【技术分享】Flutter开发技巧：如何构建高性能的应用界面',
          author: 'Flutter开发者',
          cover: 'https://i1.hdslb.com/bfs/archive/c8d7a9f2e4b5d3a9f4b2c1d6e5f4a3b2c1d6e5.jpg',
          duration: '12:18',
          play: 85000,
          danmaku: 2340,
          pubdate: 1703606400,
          cid: 197726,
        ),
        BiliVideoInfo(
          bvid: 'BV1357924680',
          aid: '135792468',
          title: '【美食制作】超详细的麻婆豆腐做法，正宗川菜教程',
          author: '川菜大师',
          cover: 'https://i3.hdslb.com/bfs/archive/d9e8b0f3c5e6d4a9f5b2c1d6e5f4a3b2c1d6e5.jpg',
          duration: '8:45',
          play: 320000,
          danmaku: 5600,
          pubdate: 1703692800,
          cid: 345678,
        ),
        BiliVideoInfo(
          bvid: 'BV2468013579',
          aid: '246801357',
          title: '【游戏实况】独立游戏新作体验，这剧情让人震撼',
          author: '游戏博主',
          cover: 'https://i0.hdslb.com/bfs/archive/e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f.jpg',
          duration: '25:30',
          play: 560000,
          danmaku: 12300,
          pubdate: 1703779200,
          cid: 456789,
        ),
        BiliVideoInfo(
          bvid: 'BV1357924680',
          aid: '135792468',
          title: '【学习笔记】数据结构与算法，面试必备知识点',
          author: '编程老师',
          cover: 'https://i1.hdslb.com/bfs/archive/f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a.jpg',
          duration: '18:22',
          play: 289000,
          danmaku: 4560,
          pubdate: 1703865600,
          cid: 567890,
        ),
        BiliVideoInfo(
          bvid: 'BV1122334455',
          aid: '112233445',
          title: '【旅行vlog】云南大理古城，风花雪月的美',
          author: '旅行达人',
          cover: 'https://i2.hdslb.com/bfs/archive/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b.jpg',
          duration: '15:45',
          play: 445000,
          danmaku: 8900,
          pubdate: 1703952000,
          cid: 678901,
        ),
      ];

      setState(() {
        _recommendItems.addAll(demoData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    _recommendItems.clear();
    _heroTagId = 0;
    await _loadRecommendData();
  }

  Future<void> _onLoad() async {
    await _loadRecommendData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('推荐'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _recommendItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recommendItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('暂无推荐内容'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendData,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    // 下拉刷新 + 网格布局
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification &&
              scrollNotification.metrics.extentAfter == 0) {
            _onLoad();
          }
          return false;
        },
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          gridDelegate: _createGridDelegate(context),
          itemCount: _recommendItems.length,
          itemBuilder: (context, index) {
            final video = _recommendItems[index];
            final heroTag = 'recommend_${video.bvid}_${_heroTagId++}';
            
            return RecommendCard(
              key: ValueKey("${video.bvid}:RecommendCard"),
              video: video,
              heroTag: heroTag,
              onTap: () {
                _navigateToVideoPage(video);
              },
            );
          },
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _createGridDelegate(BuildContext context) {
    // 完全复制bili_you的计算逻辑
    final crossAxisCount = _getRecommendColumnCount(context);
    final mainAxisExtent = (MediaQuery.of(context).size.width / crossAxisCount) * 10 / 16 + 
                           83 * MediaQuery.of(context).textScaleFactor;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      crossAxisCount: crossAxisCount,
      mainAxisExtent: mainAxisExtent,
    );
  }

  int _getRecommendColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 5;
    if (screenWidth >= 800) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  void _navigateToVideoPage(BiliVideoInfo video) {
    if (!video.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法播放此视频：缺少有效的视频ID信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerPage.withIds(
          bvid: video.bvid.isNotEmpty ? video.bvid : null,
          aid: int.tryParse(video.aid),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}