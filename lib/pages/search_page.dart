import 'package:flutter/material.dart';
import '../api/search_api.dart';
import '../models/search_result.dart';
import '../services/search_history_service.dart';
import 'player_page.dart';
import '../utils/error_handler.dart';

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
      
      // 调试：打印完整响应
      print('=== 搜索 API 响应 ===');
      print('状态码: ${response['code']}');
      print('消息: ${response['message']}');
      print('完整数据: ${response['data']}');
      
      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        List? videoList;
        
        // Bilibili API 返回的数据结构可能不同，需要判断
        if (data is Map<String, dynamic>) {
          print('data 是 Map 类型');
          print('data 的所有键: ${data.keys.toList()}');
          
          // 检查是否有 items 字段
          if (data['items'] != null) {
            print('找到 items 字段，类型: ${data['items'].runtimeType}');
            if (data['items'] is List) {
              videoList = data['items'] as List;
              print('items 是 List，长度: ${videoList.length}');
            } else if (data['items'] is Map) {
              // 如果 items 是 Map，尝试从 video 或 archive 字段提取
              final itemsMap = data['items'] as Map<String, dynamic>;
              print('items 是 Map，键: ${itemsMap.keys.toList()}');
              
              // 尝试从 archive 提取视频列表（根据错误日志中的数据结构）
              if (itemsMap['archive'] != null && itemsMap['archive'] is List) {
                videoList = itemsMap['archive'] as List?;
                print('从 items.archive 提取到列表，长度: ${videoList?.length}');
              } 
              // 尝试从 video 提取
              else if (itemsMap['video'] != null) {
                videoList = itemsMap['video'] as List?;
                print('从 items.video 提取到列表，长度: ${videoList?.length}');
              }
            }
          }
          // 尝试直接获取 result 字段（部分搜索API返回结构）
          else if (data['result'] != null) {
            print('找到 result 字段，类型: ${data['result'].runtimeType}');
            videoList = data['result'] as List?;
            print('result 是 List，长度: ${videoList?.length}');
          }
        }
        
        if (videoList != null && videoList.isNotEmpty) {
          print('准备解析 ${videoList.length} 个视频项');
          print('第一个视频项示例: ${videoList.first}');
          
          // 保存搜索历史
          await SearchHistoryService.addHistory(keyword);
          await _loadSearchHistory();
          
          setState(() {
            _searchResults = videoList!
                .map((item) => VideoSearchResult.fromJson(item))
                .toList();
            _isLoading = false;
          });
        } else {
          print('videoList 为空或 null');
          setState(() {
            _errorMessage = '未找到相关视频';
            _isLoading = false;
          });
          
          // 显示详细错误信息对话框 - 即使是"未找到相关视频"也显示详细信息
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorHandler.showErrorDialog(
              context: context,
              title: '搜索结果为空',
              error: '未找到相关视频',
              additionalInfo: '搜索关键词: $keyword\nAPI响应数据: ${ErrorHandler.formatApiResponseError(response)}',
            );
          });
        }
      } else {
        setState(() {
          _errorMessage = '搜索失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
        
        // 显示详细错误信息对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHandler.showErrorDialog(
            context: context,
            title: '搜索失败',
            error: 'API返回错误',
            additionalInfo: ErrorHandler.formatApiResponseError(response),
          );
        });
      }
    } catch (e, s) {
      print('搜索异常: $e');
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
      
      // 显示详细错误信息对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '搜索出错',
          error: e,
          stackTrace: s,
          additionalInfo: '搜索关键词: $keyword',
        );
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