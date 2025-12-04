import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../api/video_api.dart';
import '../api/danmaku_api.dart';
import '../models/video_info.dart';
import '../models/danmaku.dart';
import '../services/play_history_service.dart';
import '../services/download_service.dart';
import '../services/download_manager.dart';
import '../services/danmaku_service.dart';
import '../utils/error_handler.dart';
import '../widgets/danmaku_canvas.dart';
import '../widgets/danmaku_input.dart';
import '../widgets/danmaku_settings.dart';
import 'download_list_page.dart';

/// 带弹幕功能的视频播放器页面
class PlayerPageWithDanmaku extends StatefulWidget {
  final String bvid;
  final int? aid;

  PlayerPageWithDanmaku({
    super.key,
    required this.bvid,
    this.aid,
  }) : super() {
    assert(bvid.isNotEmpty || aid != null, 'bvid 和 aid 必须提供其中一个');
  }

  @override
  State<PlayerPageWithDanmaku> createState() => _PlayerPageWithDanmakuState();
}

class _PlayerPageWithDanmakuState extends State<PlayerPageWithDanmaku> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  VideoInfo? _videoInfo;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPartIndex = 0;
  int _selectedQuality = 80;
  
  // 弹幕相关状态
  bool _showDanmaku = true;
  bool _showDanmakuInput = false;
  bool _showDanmakuSettings = false;
  final DanmakuService _danmakuService = DanmakuService();

  // 可选画质列表
  final List<Map<String, dynamic>> _allQualityOptions = [
    {'qn': 16, 'name': '流畅'},
    {'qn': 32, 'name': '清晰'},
    {'qn': 64, 'name': '高清'},
    {'qn': 80, 'name': '超清'},
    {'qn': 112, 'name': '高清 1080P'},
    {'qn': 116, 'name': '高清 1080P60'},
  ];
  
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
    if (widget.bvid.isEmpty && widget.aid == null) {
      setState(() {
        _errorMessage = '参数错误: 缺少视频标识符 (BVID 或 AID)';
        _isLoading = false;
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
        
        await _loadAvailableQualities(_videoInfo!.cid);
        await _loadPlayUrl(_videoInfo!.cid);
        
        // 加载弹幕
        await _danmakuService.loadDanmakus(
          bvid: _videoInfo!.bvid,
          cid: _videoInfo!.cid,
        );
      } else {
        setState(() {
          _errorMessage = '加载视频失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
      }
    } catch (e, s) {
      setState(() {
        _errorMessage = '加载视频失败: $e';
        _isLoading = false;
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
      
      final response = await VideoApi.getPlayUrl(
        bvid: bvidToUse,
        cid: cid,
        qn: 80,
      );
      
      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        List<int> supportedQualities = [];
        
        if (data['accept_quality'] != null) {
          final acceptQuality = data['accept_quality'] as List;
          supportedQualities = acceptQuality.cast<int>();
        } else {
          supportedQualities = [16, 32, 64, 80, 112, 116];
        }
        
        setState(() {
          _availableQualities = _allQualityOptions
              .where((quality) => supportedQualities.contains(quality['qn']))
              .toList();
          
          if (!_availableQualities.any((q) => q['qn'] == _selectedQuality) && _availableQualities.isNotEmpty) {
            _selectedQuality = _availableQualities.first['qn'];
          }
        });
      }
    } catch (e) {
      print('获取可用画质失败: $e');
      setState(() {
        _availableQualities = List.from(_allQualityOptions);
      });
    }
  }

  /// 加载播放地址
  Future<void> _loadPlayUrl(int cid) async {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    try {
      String bvidToUse = widget.bvid;
      
      if (bvidToUse.isEmpty && _videoInfo != null && _videoInfo!.bvid.isNotEmpty) {
        bvidToUse = _videoInfo!.bvid;
      }
      
      if (bvidToUse.isEmpty) {
        throw Exception('无法获取有效的 BVID');
      }
      
      final response = await VideoApi.getPlayUrl(
        bvid: bvidToUse,
        cid: cid,
        qn: _selectedQuality,
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        String? videoUrl;

        if (data['durl'] != null) {
          final durl = data['durl'];
          if (durl is List && durl.isNotEmpty) {
            videoUrl = durl[0]['url'];
          }
        } else if (data['dash'] != null) {
          final video = data['dash']['video'];
          if (video != null && video is List && video.isNotEmpty) {
            videoUrl = video[0]['baseUrl'] ?? video[0]['base_url'];
          }
        }

        if (videoUrl != null) {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://www.bilibili.com',
            },
          );

          await _videoPlayerController!.initialize();

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
          
          _setupPlaybackListener();
        } else {
          setState(() {
            _errorMessage = '无法获取播放地址';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '获取播放地址失败: ${response['message'] ?? '未知错误'}';
          _isLoading = false;
        });
      }
    } catch (e, s) {
      setState(() {
        _errorMessage = '播放失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 设置播放监听器
  void _setupPlaybackListener() {
    if (_videoPlayerController == null) return;
    
    _videoPlayerController!.addListener(() async {
      if (_videoInfo == null || !_videoPlayerController!.value.isInitialized) return;
      
      final position = _videoPlayerController!.value.position;
      final positionSeconds = position.inSeconds;
      
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

  /// 发送弹幕
  Future<void> _sendDanmaku(Danmaku danmaku) async {
    if (_videoInfo == null) return;
    
    final success = await _danmakuService.sendDanmaku(
      bvid: _videoInfo!.bvid,
      cid: _videoInfo!.parts[_currentPartIndex].cid,
      danmaku: danmaku,
    );

    if (!success) {
      // 发送失败时添加到本地弹幕
      _danmakuService.addLocalDanmaku(danmaku);
    }

    setState(() {
      _showDanmakuInput = false;
    });
  }

  /// 切换弹幕显示
  void _toggleDanmaku() {
    setState(() {
      _showDanmaku = !_showDanmaku;
    });
  }

  /// 显示弹幕输入框
  void _showDanmakuInputDialog() {
    setState(() {
      _showDanmakuInput = true;
    });
  }

  /// 显示弹幕设置
  void _showDanmakuSettingsDialog() {
    setState(() {
      _showDanmakuSettings = true;
    });
  }

  /// 获取画质名称
  String _getQualityName(int qn) {
    final quality = _allQualityOptions.firstWhere(
      (q) => q['qn'] == qn,
      orElse: () => {'name': '未知'},
    );
    return quality['name'] ?? '未知';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _danmakuService,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_videoInfo?.title ?? '加载中...'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // 弹幕开关
            IconButton(
              icon: Icon(_showDanmaku ? Icons.comment : Icons.comment_outlined),
              onPressed: _toggleDanmaku,
              tooltip: _showDanmaku ? '隐藏弹幕' : '显示弹幕',
            ),
            
            // 弹幕设置
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showDanmakuSettingsDialog,
              tooltip: '弹幕设置',
            ),
            
            // 发送弹幕
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _showDanmakuInputDialog,
              tooltip: '发送弹幕',
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
                if (_selectedQuality == qn) return;
                
                setState(() {
                  _selectedQuality = qn;
                  _isLoading = true;
                });
                
                if (_videoInfo != null) {
                  await _loadPlayUrl(_videoInfo!.parts[_currentPartIndex].cid);
                }
              },
              itemBuilder: (context) => _availableQualities.map((quality) => PopupMenuItem<int>(
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
        body: Stack(
          children: [
            _buildBody(),
            
            // 弹幕画布
            if (_showDanmaku && _videoInfo != null)
              Consumer<DanmakuService>(
                builder: (context, danmakuService, child) {
                  return DanmakuCanvas(
                    danmakus: danmakuService.danmakus,
                    isPlaying: _videoPlayerController?.value.isPlaying ?? false,
                    opacity: danmakuService.opacity,
                    fontSize: danmakuService.fontSize,
                    showScroll: danmakuService.showScroll,
                    showTop: danmakuService.showTop,
                    showBottom: danmakuService.showBottom,
                  );
                },
              ),
            
            // 弹幕输入框
            if (_showDanmakuInput)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DanmakuInput(
                  onSend: _sendDanmaku,
                  enabled: true,
                ),
              ),
          ],
        ),
      ),
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
          child: Stack(
            children: [
              _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator()),
            ],
          ),
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
              
              // 弹幕统计
              Consumer<DanmakuService>(
                builder: (context, danmakuService, child) {
                  final stats = danmakuService.getStatistics();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '弹幕统计',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('总弹幕数: ${stats['totalCount']}'),
                          Text('滚动弹幕: ${stats['scrollCount']}'),
                          Text('顶部弹幕: ${stats['topCount']}'),
                          Text('底部弹幕: ${stats['bottomCount']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
}