import 'package:flutter/material.dart';
import '../models/video_metadata.dart';
import '../services/metadata_service.dart';

class MetadataPage extends StatefulWidget {
  const MetadataPage({super.key});

  @override
  State<MetadataPage> createState() => _MetadataPageState();
}

class _MetadataPageState extends State<MetadataPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VideoMetadata> _allVideos = [];
  List<VideoMetadata> _favoriteVideos = [];
  List<String> _categories = [];
  Map<String, List<VideoMetadata>> _categoryVideos = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMetadata();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allVideos = MetadataService().getAllMetadata();
      final favoriteVideos = MetadataService().getFavoriteVideos();
      final categories = MetadataService().getAllCategories();
      
      final categoryVideos = <String, List<VideoMetadata>>{};
      for (final category in categories) {
        categoryVideos[category] = MetadataService().getVideosByCategory(category);
      }

      setState(() {
        _allVideos = allVideos;
        _favoriteVideos = favoriteVideos;
        _categories = categories;
        _categoryVideos = categoryVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载元数据失败: $e')),
        );
      }
    }
  }

  List<VideoMetadata> _getFilteredVideos(List<VideoMetadata> videos) {
    if (_searchQuery.isEmpty) return videos;
    
    final query = _searchQuery.toLowerCase();
    return videos.where((video) {
      return video.title.toLowerCase().contains(query) ||
             (video.author?.toLowerCase().contains(query) ?? false) ||
             video.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('元数据管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部视频'),
            Tab(text: '我的收藏'),
            Tab(text: '分类浏览'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetadata,
            tooltip: '刷新',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cleanup',
                child: Text('清理过期缓存'),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Text('缓存统计'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索视频、UP主或标签...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 标签页内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoList(_getFilteredVideos(_allVideos)),
                _buildVideoList(_getFilteredVideos(_favoriteVideos)),
                _buildCategoryGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<VideoMetadata> videos) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videos.isEmpty) {
      return const Center(
        child: Text('暂无视频'),
      );
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(VideoMetadata video) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _showVideoDetails(video);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  video.cover,
                  width: 120,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // 视频信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.author ?? '未知UP主',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                        Text(
                          video.formattedViewCount,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                        Text(
                          video.formattedLikeCount,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: video.categories.take(3).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.pink[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // 收藏按钮
              IconButton(
                icon: Icon(
                  video.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: video.isFavorite ? Colors.red : null,
                ),
                onPressed: () => _toggleFavorite(video),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('暂无分类'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final videos = _categoryVideos[category] ?? [];
        
        return Card(
          child: InkWell(
            onTap: () {
              _showCategoryVideos(category, videos);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${videos.length} 个视频',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVideoDetails(VideoMetadata video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (video.description.isNotEmpty) ...[
                const Text('简介:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(video.description),
                const SizedBox(height: 16),
              ],
              if (video.tags.isNotEmpty) ...[
                const Text('标签:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: video.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Text('缓存时间: ${video.cachedAt.toString().substring(0, 19)}'),
              Text('发布时间: ${video.publishDate.toString().substring(0, 19)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite(video);
            },
            child: Text(video.isFavorite ? '取消收藏' : '添加收藏'),
          ),
        ],
      ),
    );
  }

  void _showCategoryVideos(String category, List<VideoMetadata> videos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(category)),
          body: _buildVideoList(videos),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(VideoMetadata video) async {
    try {
      await MetadataService().toggleFavorite(video.bvid);
      await _loadMetadata();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'cleanup':
        await _cleanupExpired();
        break;
      case 'stats':
        _showStats();
        break;
    }
  }

  Future<void> _cleanupExpired() async {
    try {
      await MetadataService().cleanupExpiredMetadata();
      await _loadMetadata();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清理完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败: $e')),
        );
      }
    }
  }

  void _showStats() {
    final stats = MetadataService().getCacheStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总视频数: ${stats['totalVideos']}'),
            Text('收藏视频: ${stats['favoriteVideos']}'),
            Text('分类数量: ${stats['totalCategories']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}