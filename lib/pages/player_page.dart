import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../api/video_api.dart';
import '../models/video_info.dart';
import '../services/play_history_service.dart';
import '../utils/error_handler.dart';

/// 视频播放器页面
class PlayerPage extends StatefulWidget {
  final String bvid;
  final int? aid;

  const PlayerPage({
    super.key,
    required this.bvid,
    this.aid,
  });

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
  final List<Map<String, dynamic>> _qualityOptions = [
    {'qn': 16, 'name': '流畅'},
    {'qn': 32, 'name': '清晰'},
    {'qn': 64, 'name': '高清'},
    {'qn': 80, 'name': '超清'},
    {'qn': 112, 'name': '高清 1080P'},
    {'qn': 116, 'name': '高清 1080P60'},
  ];

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
    try {
      final response = await VideoApi.getVideoDetail(
        bvid: widget.bvid,
        aid: widget.aid,
      );

      if (response['code'] == 0 && response['data'] != null) {
        setState(() {
          _videoInfo = VideoInfo.fromJson(response['data']);
          _isLoading = false;
        });
        
        // 加载播放地址
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
      setState(() {
        _errorMessage = '加载视频失败: $e';
        _isLoading = false;
      });
      
      // 显示详细错误信息对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '加载视频出错',
          error: e,
          stackTrace: s,
          additionalInfo: '视频BVID: ${widget.bvid}',
        );
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
      final response = await VideoApi.getPlayUrl(
        bvid: widget.bvid,
        cid: cid,
        qn: _selectedQuality, // 使用选定的画质
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        String? videoUrl;

        // 优先使用 durl 格式 (video_player 对 DASH 支持有限，优先用 MP4/FLV)
        if (data['durl'] != null) {
          final durl = data['durl'];
          if (durl is List && durl.isNotEmpty) {
            videoUrl = durl[0]['url'];
          }
        }
        // 降级到 DASH 格式 (可能需要额外配置)
        else if (data['dash'] != null) {
          final video = data['dash']['video'];
          if (video != null && video is List && video.isNotEmpty) {
            videoUrl = video[0]['baseUrl'] ?? video[0]['base_url'];
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
          
          setState(() {});
          
          // 监听播放位置以保存历史
          _setupPlaybackListener();
        } else {
          setState(() {
            _errorMessage = '无法获取播放地址';
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
- 画质: $_selectedQuality

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
- 画质: $_selectedQuality

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
      });
      
      // 显示详细错误信息对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '播放出错',
          error: e,
          stackTrace: s,
          additionalInfo: '视频BVID: ${widget.bvid}, CID: $cid',
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
          // 画质选择
          PopupMenuButton<int>(
            icon: const Icon(Icons.hd),
            onSelected: (qn) {
              setState(() {
                _selectedQuality = qn;
              });
              // 重新加载视频
              if (_videoInfo != null) {
                _loadPlayUrl(_videoInfo!.parts[_currentPartIndex].cid);
              }
            },
            itemBuilder: (context) => _qualityOptions
                .map((quality) => PopupMenuItem<int>(
                      value: quality['qn'],
                      child: Text(
                        quality['name'],
                        style: TextStyle(
                          fontWeight: quality['qn'] == _selectedQuality
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
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
}