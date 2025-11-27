import 'package:flutter/material.dart';
import '../api/search_api.dart';
import '../models/search_result.dart';
import '../services/search_history_service.dart';
import 'player_page.dart';

/// 搜索页面
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoSearchResult> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  /// 加载搜索历史
  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  /// 执行搜索
  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await SearchApi.searchArchive(keyword: keyword);
      
      if (response['code'] == 0 && response['data'] != null) {
        final items = response['data']['items'] as List?;
        
        if (items != null) {
          // 保存搜索历史
          await SearchHistoryService.addHistory(keyword);
          await _loadSearchHistory();
          
          setState(() {
            _searchResults = items
                .map((item) => VideoSearchResult.fromJson(item))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '搜索失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilibili 搜索'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索视频...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          
          // 结果列表
          Expanded(
            child: _buildResultsView(),
          ),
        ],
      ),
    );
  }

  /// 构建结果视图
  Widget _buildResultsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildSearchHistory();
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final video = _searchResults[index];
        return ListTile(
          leading: Image.network(
            video.cover,
            width: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.broken_image, size: 60),
          ),
          title: Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'UP: ${video.author} | 播放: ${_formatPlayCount(video.play)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(video.duration),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlayerPage(bvid: video.bvid),
              ),
            );
          },
        );
      },
    );
  }

  /// 格式化播放量
  String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000.0).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 构建搜索历史视图
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(child: Text('输入关键词搜索视频'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '搜索历史',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () async {
                await SearchHistoryService.clearHistory();
                await _loadSearchHistory();
              },
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map((keyword) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(keyword),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () async {
              await SearchHistoryService.removeHistory(keyword);
              await _loadSearchHistory();
            },
          ),
          onTap: () {
            _searchController.text = keyword;
            _performSearch(keyword);
          },
        )),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
