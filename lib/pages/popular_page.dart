import 'package:flutter/material.dart';
import '../widgets/popular_video_card.dart';
import '../models/bili_video_info.dart';
import 'player_page.dart';

/// 热门页面 - 完全基于bili_you热门页面设计
class PopularPage extends StatefulWidget {
  const PopularPage({super.key});

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<BiliVideoInfo> _popularItems = [];
  bool _isLoading = false;
  
  int _heroTagId = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPopularData();
  }

  Future<void> _loadPopularData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟热门数据
      await Future.delayed(const Duration(seconds: 1));
      
      final demoData = [
        BiliVideoInfo(
          bvid: 'BV1hT421h7J8',
          aid: '1351436293',
          title: '【年度热门】2024年度盘点：那些刷爆全网的瞬间',
          author: '热点追踪',
          cover: 'https://i0.hdslb.com/bfs/archive/a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b.jpg',
          duration: '10:25',
          play: 3500000,
          danmaku: 28600,
          pubdate: 1704038400,
          cid: 1477599773,
        ),
        BiliVideoInfo(
          bvid: 'BV1Rm421G7q3',
          aid: '1368446653',
          title: '【游戏爆款】独立游戏新作，首日销量破百万',
          author: '游戏资讯',
          cover: 'https://i1.hdslb.com/bfs/archive/b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c.jpg',
          duration: '8:15',
          play: 2800000,
          danmaku: 19800,
          pubdate: 1704124800,
          cid: 1477599774,
        ),
        BiliVideoInfo(
          bvid: 'BV1YW411T7Y9',
          aid: '1317167706',
          title: '【音乐现场】演唱会现场版，这声线太绝了',
          author: '音乐分享',
          cover: 'https://i2.hdslb.com/bfs/archive/c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d.jpg',
          duration: '6:42',
          play: 2100000,
          danmaku: 15600,
          pubdate: 1704211200,
          cid: 1477599775,
        ),
        BiliVideoInfo(
          bvid: 'BV1xH4y1h7YB',
          aid: '1369509813',
          title: '【美食探店】米其林餐厅体验，这价格值吗？',
          author: '美食博主',
          cover: 'https://i3.hdslb.com/bfs/archive/d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e.jpg',
          duration: '12:30',
          play: 1800000,
          danmaku: 12400,
          pubdate: 1704297600,
          cid: 1477599776,
        ),
        BiliVideoInfo(
          bvid: 'BV1uS4y1U7UF',
          aid: '850361975',
          title: '【科技前沿】AI技术突破，未来已来',
          author: '科技解说',
          cover: 'https://i0.hdslb.com/bfs/archive/e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f.jpg',
          duration: '15:20',
          play: 1500000,
          danmaku: 9800,
          pubdate: 1704384000,
          cid: 123456,
        ),
        BiliVideoInfo(
          bvid: 'BV6jL8m4O5P6',
          aid: '432109876',
          title: '【旅行攻略】穷游攻略，如何用最少的钱玩最多的地方',
          author: '旅游达人',
          cover: 'https://i1.hdslb.com/bfs/archive/f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a.jpg',
          duration: '18:45',
          play: 1200000,
          danmaku: 7600,
          pubdate: 1704470400,
          cid: 234567,
        ),
      ];

      setState(() {
        _popularItems.addAll(demoData);
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
    _popularItems.clear();
    _heroTagId = 0;
    await _loadPopularData();
  }

  Future<void> _onLoad() async {
    await _loadPopularData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('热门'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _popularItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_popularItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('暂无热门内容'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPopularData,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    // 下拉刷新 + 列表布局
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
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: _popularItems.length,
          itemBuilder: (context, index) {
            final video = _popularItems[index];
            final heroTag = 'popular_${video.bvid}_${_heroTagId++}';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2), // 减小垂直间距防止溢出
              child: PopularVideoCard(
                video: video,
                heroTag: heroTag,
                onTap: () {
                  _navigateToVideoPage(video);
                },
              ),
            );
          },
        ),
      ),
    );
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