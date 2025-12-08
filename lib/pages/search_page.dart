import 'package:flutter/material.dart';
import '../api/search_api.dart';
import '../models/search_result.dart';
import '../services/search_history_service.dart';
import '../services/network_service.dart';
import 'player_page.dart';
import 'quality_test_page.dart';
import '../utils/error_handler.dart';
import '../widgets/theme_switch_button.dart';
import '../widgets/network_status_widget.dart';
import 'comment_page.dart';

/// 搜索页面
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final NetworkService _networkService = NetworkService();
  
  List<VideoSearchResult> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSearching = false;

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
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      await SearchHistoryService.addToHistory(keyword);
      
      final response = await _networkService.executeWithNetworkCheck(
        () => SearchApi.searchArchive(keyword: keyword),
        timeout: const Duration(seconds: 15),
        retryConfig: RetryConfig.networkConfig,
      );
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
          print('=== API 响应数据分析 ===');
          print('data 是 Map 类型');
          print('data 的所有键: ${data.keys.toList()}');
          print('data 完整内容: $data');
          
          // 检查是否有 items 字段
          if (data['items'] != null) {
            print('找到 items 字段，类型: ${data['items'].runtimeType}');
            if (data['items'] is List) {
              videoList = data['items'] as List;
              print('items 是 List，长度: ${videoList.length}');
              if (videoList.isNotEmpty) {
                print('第一个视频项原始数据: ${videoList.first}');
                print('第一个视频项字段: ${(videoList.first as Map).keys.toList()}');
              }
            } else if (data['items'] is Map) {
              // 如果 items 是 Map，尝试从 video 或 archive 字段提取
              final itemsMap = data['items'] as Map<String, dynamic>;
              print('items 是 Map，键: ${itemsMap.keys.toList()}');
              print('items 完整内容: $itemsMap');
              
              // 尝试从 archive 提取视频列表（根据错误日志中的数据结构）
              if (itemsMap['archive'] != null && itemsMap['archive'] is List) {
                videoList = itemsMap['archive'] as List?;
                print('从 items.archive 提取到列表，长度: ${videoList?.length}');
                if (videoList != null && videoList.isNotEmpty) {
                  print('第一个 archive 项: ${videoList.first}');
                  print('第一个 archive 项字段: ${(videoList.first as Map).keys.toList()}');
                }
              } 
              // 尝试从 video 提取
              else if (itemsMap['video'] != null) {
                videoList = itemsMap['video'] as List?;
                print('从 items.video 提取到列表，长度: ${videoList?.length}');
                if (videoList != null && videoList.isNotEmpty) {
                  print('第一个 video 项: ${videoList.first}');
                  print('第一个 video 项字段: ${(videoList.first as Map).keys.toList()}');
                }
              }
            }
          }
          // 尝试直接获取 result 字段（部分搜索API返回结构）
          else if (data['result'] != null) {
            print('找到 result 字段，类型: ${data['result'].runtimeType}');
            videoList = data['result'] as List?;
            print('result 是 List，长度: ${videoList?.length}');
            if (videoList != null && videoList.isNotEmpty) {
              print('第一个 result 项: ${videoList.first}');
              print('第一个 result 项字段: ${(videoList.first as Map).keys.toList()}');
            }
          }
          
          // 尝试其他可能的字段名
          else {
            print('未找到预期的字段，检查所有可能的列表字段...');
            for (final key in data.keys) {
              final value = data[key];
              if (value is List && value.isNotEmpty) {
                print('发现列表字段: $key，长度: ${value.length}');
                print('第一个元素类型: ${value.first.runtimeType}');
                if (value.first is Map) {
                  final firstItem = value.first as Map;
                  print('第一个元素字段: ${firstItem.keys.toList()}');
                  
                  // 检查是否包含视频相关字段
                  final hasVideoFields = firstItem.keys.any((k) => 
                    ['title', 'bvid', 'aid', 'author', 'cover', 'play'].contains(k));
                  
                  if (hasVideoFields) {
                    print('✓ $key 字段包含视频信息，使用此列表');
                    videoList = value;
                    break;
                  }
                }
              }
            }
          }
          
          // 如果仍然没有找到视频列表，尝试深度搜索
          if (videoList == null) {
            print('尝试深度搜索嵌套结构...');
            videoList = _deepSearchVideoList(data);
          }
        }
        
        if (videoList != null && videoList.isNotEmpty) {
          print('准备解析 ${videoList.length} 个视频项');
          print('第一个视频项示例: ${videoList.first}');
          
          // 保存搜索历史
          await SearchHistoryService.addHistory(keyword);
          await _loadSearchHistory();
          
          // 解析搜索结果
          final results = videoList
              .map((item) => VideoSearchResult.fromJson(item))
              .where((result) => result.hasValidId) // 只保留有有效ID的结果
              .toList();
          
          print('成功解析 ${results.length} 个有效视频项');
          
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isLoading = false;
              _isSearching = false;
            });
          }
          
          // 如果没有有效结果，显示提示
          if (results.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('搜索结果中没有找到有效的视频ID'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        } else {
          print('videoList 为空或 null');
          if (mounted) {
            setState(() {
              _errorMessage = '未找到相关视频';
              _isLoading = false;
              _isSearching = false;
            });
          }
          
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
        if (mounted) {
          setState(() {
            _errorMessage = '搜索失败: ${response['message'] ?? '未知错误'}';
            _isLoading = false;
            _isSearching = false;
          });
        }
        
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
      if (mounted) {
        setState(() {
          _errorMessage = _networkService.isOffline ? '网络连接已断开' : '网络错误: $e';
          _isLoading = false;
          _isSearching = false;
        });
      }
      
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
        title: Row(
          children: [
            const Text('Bilibili 搜索'),
            const SizedBox(width: 8),
            // 网络状态指示器
            NetworkStatusWidget(
              showLabel: false,
              onlineColor: Colors.green,
              offlineColor: Colors.red,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          const ThemeSwitchButton(),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToPlayHistory(),
            tooltip: '播放历史',
          ),
          IconButton(
            icon: const Icon(Icons.high_quality),
            onPressed: _openQualityTest,
            tooltip: '画质测试',
          ),
        ],
      ),
      body: Column(
        children: [
          // 网络状态栏
          NetworkStatusBar(
            height: 24,
            animationDuration: const Duration(milliseconds: 300),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<NetworkService>(
              builder: (context, networkService, child) {
                return TextField(
                  controller: _searchController,
                  enabled: networkService.isOnline,
                  decoration: InputDecoration(
                    hintText: networkService.isOnline ? '搜索视频...' : '网络连接已断开',
                    prefixIcon: networkService.isOnline 
                        ? const Icon(Icons.search) 
                        : const Icon(Icons.wifi_off, color: Colors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: !networkService.isOnline,
                    fillColor: Colors.grey.shade100,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _errorMessage = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  onSubmitted: networkService.isOnline ? _performSearch : null,
                );
              },
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
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在搜索...'),
              ],
            ),
          );
        }

        if (_errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    networkService.isOffline ? Icons.wifi_off : Icons.error_outline,
                    size: 64,
                    color: networkService.isOffline ? Colors.grey : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: networkService.isOffline ? Colors.grey[600] : Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (networkService.isOffline)
                    Text(
                      '请检查网络连接后重试',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: networkService.isOnline 
                        ? () => _performSearch(_searchController.text)
                        : () {
                            networkService.checkConnectivity();
                            if (networkService.isOnline) {
                              _performSearch(_searchController.text);
                            }
                          },
                    icon: const Icon(Icons.refresh),
                    label: Text(networkService.isOffline ? '检查网络' : '重试'),
                  ),
                ],
              ),
            ),
          );
        }

        if (_searchResults.isEmpty) {
          return _buildSearchHistory();
        }

        return NetworkListView(
          children: _searchResults.map((video) => _buildVideoCard(video)).toList(),
        );
      },
    );
  }

  /// 构建视频卡片
  Widget _buildVideoCard(VideoSearchResult video) {
    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                video.cover,
                width: 120,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.broken_image, size: 60),
              ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 评论按钮
                IconButton(
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  onPressed: () {
                    final String? validBvid = video.bvid.isNotEmpty ? video.bvid : null;
                    final int? validAid = video.aid != 0 ? video.aid : null;
                    
                    if (validBvid == null && validAid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('无法查看评论：缺少有效的视频ID信息'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentPage(
                          bvid: validBvid ?? '',
                          aid: validAid,
                        ),
                      ),
                    );
                  },
                  tooltip: '查看评论',
                ),
                Text(video.duration),
              ],
            ),
            onTap: () {
            // 验证视频ID是否有效
            if (!video.hasValidId) {
              // 显示错误提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法播放此视频：缺少有效的视频ID信息'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            
            // 只传递有效的 ID
            final String? validBvid = video.bvid.isNotEmpty ? video.bvid : null;
            final int? validAid = video.aid != 0 ? video.aid : null;
            
            // 确保至少有一个有效的 ID
            if (validBvid == null && validAid == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无法播放此视频：缺少有效的视频ID信息'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlayerPage.withIds(
                  bvid: validBvid,
                  aid: validAid,
                ),
              ),
            );
          },
        ),
        );
  }
  }

  /// 格式化播放量
  String _formatPlayCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000.0).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 导航到播放历史页面
  void _navigateToPlayHistory() {
    // TODO: 实现播放历史页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('播放历史页面开发中...')),
    );
  }

  /// 打开画质测试页面
  void _openQualityTest() {
    // 使用一个常见的测试视频
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QualityTestPage(
          bvid: 'BV1xx411c7mD', // 测试视频
          cid: 19772637, // 对应的 CID
        ),
      ),
    );
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

  /// 深度搜索视频列表
  List? _deepSearchVideoList(dynamic data, {int depth = 0, int maxDepth = 3}) {
    if (depth > maxDepth) return null;
    
    if (data is List && data.isNotEmpty) {
      // 检查是否是视频列表
      final firstItem = data.first;
      if (firstItem is Map) {
        final hasVideoFields = firstItem.keys.any((k) => 
          ['title', 'bvid', 'aid', 'author', 'cover', 'play'].contains(k));
        
        if (hasVideoFields) {
          print('✓ 在深度 $depth 处找到视频列表，长度: ${data.length}');
          return data;
        }
      }
    } else if (data is Map) {
      // 递归搜索 Map 中的所有值
      for (final key in data.keys) {
        final value = data[key];
        if (value is List || value is Map) {
          final result = _deepSearchVideoList(value, depth: depth + 1);
          if (result != null) {
            print('✓ 在字段 $key (深度 ${depth + 1}) 找到视频列表');
            return result;
          }
        }
      }
    }
    
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}