import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../api/video_api.dart';
import '../models/video_info.dart';
import '../services/play_history_service.dart';
import '../services/download_service.dart';
import '../utils/error_handler.dart';

/// 测试画质切换功能的简化版本
class QualityTestPage extends StatefulWidget {
  final String bvid;
  final int cid;

  const QualityTestPage({
    super.key,
    required this.bvid,
    required this.cid,
  });

  @override
  State<QualityTestPage> createState() => _QualityTestPageState();
}

class _QualityTestPageState extends State<QualityTestPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedQuality = 80;
  
  final List<Map<String, dynamic>> _allQualities = [
    {'qn': 16, 'name': '流畅'},
    {'qn': 32, 'name': '清晰'},
    {'qn': 64, 'name': '高清'},
    {'qn': 80, 'name': '超清'},
    {'qn': 112, 'name': '高清 1080P'},
    {'qn': 116, 'name': '高清 1080P60'},
  ];
  
  List<Map<String, dynamic>> _availableQualities = [];
  Map<String, dynamic> _currentPlayData = {};

  @override
  void initState() {
    super.initState();
    _testQualitySwitch();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  /// 测试画质切换
  Future<void> _testQualitySwitch() async {
    await _loadAvailableQualities();
    await _loadVideo(_selectedQuality);
  }

  /// 获取可用画质
  Future<void> _loadAvailableQualities() async {
    try {
      final response = await VideoApi.getPlayUrl(
        bvid: widget.bvid,
        cid: widget.cid,
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
          _availableQualities = _allQualities
              .where((quality) => supportedQualities.contains(quality['qn']))
              .toList();
        });
      }
    } catch (e) {
      print('获取可用画质失败: $e');
      setState(() {
        _availableQualities = List.from(_allQualities);
      });
    }
  }

  /// 加载指定画质的视频
  Future<void> _loadVideo(int quality) async {
    // 释放旧控制器
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await VideoApi.getPlayUrl(
        bvid: widget.bvid,
        cid: widget.cid,
        qn: quality,
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        String? videoUrl;
        int actualQuality = quality;

        if (data['quality'] != null) {
          actualQuality = data['quality'];
        }

        if (data['durl'] != null) {
          final durl = data['durl'];
          if (durl is List && durl.isNotEmpty) {
            videoUrl = durl[0]['url'];
          }
        }

        if (videoUrl != null) {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Referer': 'https://www.bilibili.com',
            },
          );

          await _videoPlayerController!.initialize();

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: false, // 测试时不要自动播放
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
          );

          setState(() {
            _isLoading = false;
            _selectedQuality = actualQuality;
            _currentPlayData = data;
          });
        } else {
          setState(() {
            _errorMessage = '无法获取播放地址';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 错误: ${response['message']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('画质切换测试 - ${widget.bvid}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<int>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hd),
                const SizedBox(width: 4),
                Text(_getQualityName(_selectedQuality)),
              ],
            ),
            onSelected: (qn) async {
              if (_selectedQuality == qn) return;
              
              setState(() {
                _selectedQuality = qn;
              });
              
              await _loadVideo(qn);
            },
            itemBuilder: (context) => _availableQualities.map((quality) => PopupMenuItem<int>(
              value: quality['qn'],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(quality['name']),
                  if (quality['qn'] == _selectedQuality)
                    const Icon(Icons.check, color: Colors.blue),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 视频播放器
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: _buildVideoPlayer(),
            ),
          ),
          
          // 信息面板
          Expanded(
            flex: 1,
            child: _buildInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testQualitySwitch,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const Center(child: Text('播放器未初始化'));
  }

  Widget _buildInfoPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('当前画质: ${_getQualityName(_selectedQuality)} ($_selectedQuality)'),
        const SizedBox(height: 8),
        Text('可用画质数量: ${_availableQualities.length}'),
        const SizedBox(height: 8),
        Text('可用画质: ${_availableQualities.map((q) => q['name']).join(', ')}'),
        const SizedBox(height: 16),
        
        if (_currentPlayData.isNotEmpty) ...[
          const Text('API 响应信息:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_currentPlayData['quality'] != null)
            Text('返回画质: ${_currentPlayData['quality']}'),
          if (_currentPlayData['durl'] != null) ...[
            Text('文件大小: '
                '${((_currentPlayData['durl'][0]['size'] ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB'),
            Text('时长: '
                '${Duration(seconds: (_currentPlayData['durl'][0]['length'] ?? 0)).inSeconds} 秒'),
          ],
          if (_currentPlayData['accept_quality'] != null)
            Text('支持画质: ${_currentPlayData['accept_quality']}'),
        ],
      ],
    );
  }

  String _getQualityName(int qn) {
    final quality = _allQualities.firstWhere(
      (q) => q['qn'] == qn,
      orElse: () => {'name': '未知'},
    );
    return quality['name'] ?? '未知';
  }
}