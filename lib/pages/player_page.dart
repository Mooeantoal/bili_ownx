import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../api/video_api.dart';
import '../models/video_info.dart';
import '../services/play_history_service.dart';
import '../services/download_service.dart';
import '../services/download_manager.dart';
import '../utils/error_handler.dart';
import 'download_list_page.dart';

/// 视频播放器页面
class PlayerPage extends StatefulWidget {
  final String bvid;
  final int? aid;

  PlayerPage({
    super.key,
    required this.bvid,
    this.aid,
  }) : super() {
    assert(bvid.isNotEmpty || aid != null, 'bvid 和 aid 必须提供其中一个');
  }

  /// 工厂构造函数，用于处理可选的 bvid
  factory PlayerPage.withIds({
    Key? key,
    String? bvid,
    int? aid,
  }) {
    assert(bvid != null || aid != null, 'bvid 和 aid 必须提供其中一个');
    return PlayerPage(
      key: key,
      bvid: bvid ?? '',
      aid: aid,
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  VideoInfo? _videoInfo;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPartIndex = 0;
  int _selectedQuality = 80; // 默认超清画质
  
  // 可选画质列表
  final List<Map<String, dynamic>> _allQualityOptions = [
    {'qn': 16, 'name': '流畅'},
    {'qn': 32, 'name': '清晰'},
    {'qn': 64, 'name': '高清'},
    {'qn': 80, 'name': '超清'},
    {'qn': 112, 'name': '高清 1080P'},
    {'qn': 116, 'name': '高清 1080P60'},
  ];
  
  // 当前视频支持的画质列表
  List<Map<String, dynamic>> _availableQualities = [];

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  /// 加载视频信息
  Future<void> _loadVideoInfo() async {
    // 参数验证
    if (widget.bvid.isEmpty && widget.aid == null) {
      setState(() {
        _errorMessage = '参数错误: 缺少视频标识符 (BVID 或 AID)';
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '参数错误',
          error: '缺少视频标识符',
          stackTrace: StackTrace.current,
          additionalInfo: '''BVID: "${widget.bvid}"
AID: ${widget.aid}

可能的原因:
1. 搜索结果中缺少视频ID信息
2. API返回数据格式异常
3. 视频已被删除或不可访问

请尝试重新搜索或选择其他视频。''',
        );
      });
      return;
    }
    
    try {
      final response = await VideoApi.getVideoDetail(
        bvid: widget.bvid,
        aid: widget.aid,
      );

      if (response['code'] == 0 && response['data'] != null) {
        setState(() {
          _videoInfo = VideoInfo.fromJson(response['data']);
        });
        
        // 先获取可用画质列表
        await _loadAvailableQualities(_videoInfo!.cid);
        
        // 然后加载播放地址
        await _loadPlayUrl(_videoInfo!.cid);
      } else {
        setState(() {
          _errorMessage = '加载视频失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
        
        // 显示详细错误信息对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHandler.showErrorDialog(
            context: context,
            title: '加载视频失败',
            error: 'API返回错误 (code: ${response['code']})',
            stackTrace: StackTrace.current,
            additionalInfo: '''请求参数:
- BVID: ${widget.bvid}
- AID: ${widget.aid}

API响应:
${ErrorHandler.formatApiResponseError(response)}

可能的原因:
1. 视频不存在或已被删除
2. 视频为私密或需要登录
3. 请求参数格式错误
4. API请求频率过高
5. 网络连接问题''',
          );
        });
      }
    } catch (e, s) {
      String detailedError = e.toString();
      String additionalInfo = '''请求参数:
- BVID: "${widget.bvid}"
- AID: ${widget.aid}

错误详情:''';
      
      // 如果是 DioException，提供更详细的信息
      if (e.toString().contains('DioException')) {
        additionalInfo += '''
- 错误类型: DioException
- 可能原因: API请求失败、网络连接问题、服务器错误
- 建议: 检查网络连接，稍后重试''';
      } else if (e.toString().contains('FormatException')) {
        additionalInfo += '''
- 错误类型: 数据格式错误
- 可能原因: API返回数据格式异常
- 建议: 检查API响应数据格式''';
      } else {
        additionalInfo += '''
- 错误类型: ${e.runtimeType}
- 错误信息: $e''';
      }
      
      setState(() {
        _errorMessage = '加载视频失败: $detailedError';
        _isLoading = false;
      });
      
      // 显示详细错误信息对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '加载视频出错',
          error: detailedError,
          stackTrace: s,
          additionalInfo: additionalInfo,
        );
      });
    }
  }

  /// 获取视频支持的画质列表
  Future<void> _loadAvailableQualities(int cid) async {
    try {
      String bvidToUse = widget.bvid;
      if (bvidToUse.isEmpty && _videoInfo != null && _videoInfo!.bvid.isNotEmpty) {
        bvidToUse = _videoInfo!.bvid;
      }
      
      if (bvidToUse.isEmpty) return;
      
      // 使用默认画质请求，获取支持的画质列表
      final response = await VideoApi.getPlayUrl(
        bvid: bvidToUse,
        cid: cid,
        qn: 80, // 使用超清画质查询
      );
      
      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        
        // 从 API 响应中获取支持的画质
        List<int> supportedQualities = [];
        
        if (data['accept_quality'] != null) {
          // 如果有 accept_quality 字段，直接使用
          final acceptQuality = data['accept_quality'] as List;
          supportedQualities = acceptQuality.cast<int>();
        } else {
          // 否则根据常见的画质等级推断
          supportedQualities = [16, 32, 64, 80, 112, 116];
        }
        
        // 过滤出可用的画质选项
        setState(() {
          _availableQualities = _allQualityOptions
              .where((quality) => supportedQualities.contains(quality['qn']))
              .toList();
          
          // 如果当前选择的画质不可用，选择第一个可用的画质
          if (!_availableQualities.any((q) => q['qn'] == _selectedQuality) && _availableQualities.isNotEmpty) {
            _selectedQuality = _availableQualities.first['qn'];
            print('自动选择可用画质: ${_getQualityName(_selectedQuality)}');
          }
        });
        
        print('可用画质列表: ${_availableQualities.map((q) => '${q['name']}(${q['qn']})').join(', ')}');
      }
    } catch (e) {
      print('获取可用画质失败: $e');
      // 使用默认画质列表
      setState(() {
        _availableQualities = List.from(_allQualityOptions);
      });
    }
  }

  /// 加载播放地址
  Future<void> _loadPlayUrl(int cid) async {
    // 释放旧控制器
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    try {
      // 确定要使用的 bvid
      String bvidToUse = widget.bvid;
      
      // 如果 widget.bvid 为空，尝试从 _videoInfo 获取
      if (bvidToUse.isEmpty && _videoInfo != null && _videoInfo!.bvid.isNotEmpty) {
        bvidToUse = _videoInfo!.bvid;
        print('使用从视频信息中获取的 BVID: $bvidToUse');
      }
      
      // 最终验证
      if (bvidToUse.isEmpty) {
        throw Exception('无法获取有效的 BVID：widget.bvid 为空，且无法从视频信息中获取');
      }
      
      print('开始加载播放地址: 画质=$_selectedQuality (${_getQualityName(_selectedQuality)})');
      
      final response = await VideoApi.getPlayUrl(
        bvid: bvidToUse,
        cid: cid,
        qn: _selectedQuality, // 使用选定的画质
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        String? videoUrl;
        int actualQuality = _selectedQuality;

        // 检查实际返回的画质
        if (data['quality'] != null) {
          actualQuality = data['quality'];
          print('API 返回的实际画质: $actualQuality (${_getQualityName(actualQuality)})');
          
          // 如果实际画质与请求画质不同，更新状态
          if (actualQuality != _selectedQuality) {
            print('画质自动调整: ${_getQualityName(_selectedQuality)} -> ${_getQualityName(actualQuality)}');
            _selectedQuality = actualQuality;
          }
        }

        // 优先使用 durl 格式 (video_player 对 DASH 支持有限，优先用 MP4/FLV)
        if (data['durl'] != null) {
          final durl = data['durl'];
          if (durl is List && durl.isNotEmpty) {
            videoUrl = durl[0]['url'];
            final size = durl[0]['size'];
            print('获取到 MP4/FLV 播放地址，文件大小: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
          }
        }
        // 降级到 DASH 格式 (可能需要额外配置)
        else if (data['dash'] != null) {
          final video = data['dash']['video'];
          if (video != null && video is List && video.isNotEmpty) {
            videoUrl = video[0]['baseUrl'] ?? video[0]['base_url'];
            print('获取到 DASH 播放地址，视频流数量: ${video.length}');
          }
        }

        if (videoUrl != null) {
          // 初始化播放器
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Referer': 'https://www.bilibili.com',
            },
          );

          await _videoPlayerController!.initialize();

          // 恢复播放进度
          final savedPosition = await PlayHistoryService.getPosition(widget.bvid);
          if (savedPosition != null && savedPosition > 0) {
            await _videoPlayerController!.seekTo(Duration(seconds: savedPosition));
          }

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
          
          setState(() {
            _isLoading = false;
          });
          
          // 监听播放位置以保存历史
          _setupPlaybackListener();
          
          print('播放器初始化成功，当前画质: ${_getQualityName(_selectedQuality)}');
        } else {
          setState(() {
            _errorMessage = '无法获取播放地址';
            _isLoading = false;
          });
          
          // 显示详细错误信息对话框
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorHandler.showErrorDialog(
              context: context,
              title: '播放地址解析失败',
              error: '无法获取播放地址',
              stackTrace: StackTrace.current,
              additionalInfo: '''请求参数:
- BVID: ${widget.bvid}
- CID: $cid
- 画质: $_selectedQuality (${_getQualityName(_selectedQuality)})

API响应:
${ErrorHandler.formatApiResponseError(response)}

可能的原因:
1. 视频播放地址解析失败
2. 选择的画质不支持
3. 视频正在转码中
4. 地区限制或版权限制
5. 需要登录才能观看''',
            );
          });
        }
      } else {
        setState(() {
          _errorMessage = '获取播放地址失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
        
        // 显示详细错误信息对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHandler.showErrorDialog(
            context: context,
            title: '获取播放地址失败',
            error: 'API返回错误 (code: ${response['code']})',
            stackTrace: StackTrace.current,
            additionalInfo: '''请求参数:
- BVID: ${widget.bvid}
- CID: $cid
- 画质: $_selectedQuality (${_getQualityName(_selectedQuality)})

API响应:
${ErrorHandler.formatApiResponseError(response)}

可能的原因:
1. 视频播放权限不足
2. 请求参数错误
3. API服务异常
4. 网络连接问题
5. 需要重新登录''',
          );
        });
      }
    } catch (e, s) {
      setState(() {
        _errorMessage = '播放失败: $e';
        _isLoading = false;
      });
      
      // 显示详细错误信息对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '播放出错',
          error: e,
          stackTrace: s,
          additionalInfo: '视频BVID: ${widget.bvid}, CID: $cid, 画质: $_selectedQuality',
        );
      });
    }
  }

  /// 设置播放监听器
  void _setupPlaybackListener() {
    if (_videoPlayerController == null) return;
    
    // 每30秒保存一次播放进度
    _videoPlayerController!.addListener(() async {
      if (_videoInfo == null || !_videoPlayerController!.value.isInitialized) return;
      
      final position = _videoPlayerController!.value.position;
      final positionSeconds = position.inSeconds;
      
      // 每30秒或播放进度变化较大时保存
      if (positionSeconds % 30 == 0 && positionSeconds > 0) {
        await PlayHistoryService.addHistory(
          bvid: _videoInfo!.bvid,
          title: _videoInfo!.title,
          cover: _videoInfo!.cover,
          position: positionSeconds,
          duration: _videoInfo!.duration,
        );
      }
    });
  }

  /// 切换分P
  Future<void> _switchPart(int index) async {
    if (_videoInfo == null || index >= _videoInfo!.parts.length) return;

    setState(() {
      _currentPartIndex = index;
      _isLoading = true;
      _chewieController?.dispose();
      _videoPlayerController?.dispose();
      _chewieController = null;
      _videoPlayerController = null;
    });

    await _loadPlayUrl(_videoInfo!.parts[index].cid);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_videoInfo?.title ?? '加载中...'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 下载按钮
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadVideo,
            tooltip: '下载视频',
          ),
          
          // 画质选择
          PopupMenuButton<int>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hd),
                const SizedBox(width: 4),
                Text(
                  _getQualityName(_selectedQuality),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            onSelected: (qn) async {
              if (_selectedQuality == qn) return; // 相同画质不切换
              
              // 显示切换提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('正在切换到${_getQualityName(qn)}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
              
              setState(() {
                _selectedQuality = qn;
                _isLoading = true;
              });
              
              // 重新加载视频
              if (_videoInfo != null) {
                try {
                  await _loadPlayUrl(_videoInfo!.parts[_currentPartIndex].cid);
                  
                  // 显示切换成功提示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已切换到${_getQualityName(qn)}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // 切换失败，恢复原画质
                  setState(() {
                    _selectedQuality = _qualityOptions.first['qn']; // 恢复默认画质
                    _isLoading = false;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('画质切换失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => _availableQualities.isEmpty
                ? _allQualityOptions.map((quality) => PopupMenuItem<int>(
                      value: quality['qn'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            quality['name'],
                            style: TextStyle(
                              fontWeight: quality['qn'] == _selectedQuality
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (quality['qn'] == _selectedQuality)
                            const Icon(Icons.check, color: Colors.blue),
                        ],
                      ),
                    )).toList()
                : _availableQualities.map((quality) => PopupMenuItem<int>(
                      value: quality['qn'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            quality['name'],
                            style: TextStyle(
                              fontWeight: quality['qn'] == _selectedQuality
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (quality['qn'] == _selectedQuality)
                            const Icon(Icons.check, color: Colors.blue),
                        ],
                      ),
                    )).toList(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadVideoInfo,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_videoInfo == null) {
      return const Center(child: Text('视频信息加载失败'));
    }

    return Column(
      children: [
        // 视频播放器
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
        ),
        
        // 视频信息
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 标题
              Text(
                _videoInfo!.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              // UP主和播放信息
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(_videoInfo!.author),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatDuration(_videoInfo!.duration)),
                ],
              ),
              const SizedBox(height: 16),
              
              // 简介
              if (_videoInfo!.desc.isNotEmpty) ...[
                Text(
                  '简介',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_videoInfo!.desc),
                const SizedBox(height: 16),
              ],
              
              // 分P列表
              if (_videoInfo!.parts.length > 1) ...[
                Text(
                  '选集 (${_videoInfo!.parts.length}P)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._videoInfo!.parts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final part = entry.value;
                  return ListTile(
                    selected: index == _currentPartIndex,
                    title: Text('P${part.page} ${part.title}'),
                    trailing: Text(_formatDuration(part.duration)),
                    onTap: () => _switchPart(index),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// 下载视频
  Future<void> _downloadVideo() async {
    if (_videoInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频信息未加载完成')),
      );
      return;
    }

    final currentPart = _videoInfo!.parts[_currentPartIndex];

    try {
      // 显示下载对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('添加到下载队列'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('标题: ${_videoInfo!.title}'),
              const SizedBox(height: 8),
              Text('UP主: ${_videoInfo!.author}'),
              const SizedBox(height: 8),
              Text('分P: P${currentPart.page} ${currentPart.title}'),
              const SizedBox(height: 8),
              Text('画质: ${_getQualityName(_selectedQuality)}'),
              const SizedBox(height: 16),
              const Text('确定要添加到下载队列吗？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('添加'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 添加到下载队列
      final manager = DownloadManager();
      final taskId = await manager.addDownloadTask(
        bvid: _videoInfo!.bvid,
        cid: currentPart.cid,
        title: _videoInfo!.title,
        cover: _videoInfo!.cover,
        author: _videoInfo!.author,
        quality: _selectedQuality,
        qualityName: _getQualityName(_selectedQuality),
        partIndex: currentPart.page,
        partTitle: currentPart.title,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加到下载队列'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadListPage(),
                ),
              );
            },
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加下载失败: $e')),
      );
    }
  }

  /// 获取画质名称
  String _getQualityName(int qn) {
    final quality = _qualityOptions.firstWhere(
      (q) => q['qn'] == qn,
      orElse: () => {'name': '未知'},
    );
    return quality['name'] ?? '未知';
  }
}