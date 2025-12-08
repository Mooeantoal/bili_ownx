import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/pip_service.dart';

/// 画中画功能测试页面
class PiPTestPage extends StatefulWidget {
  const PiPTestPage({super.key});

  @override
  State<PiPTestPage> createState() => _PiPTestPageState();
}

class _PiPTestPageState extends State<PiPTestPage> 
    with PiPStateMixin, TickerProviderStateMixin {
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  final PiPService _pipService = PiPService();

  // 测试视频URL（使用公开的测试视频）
  final String _testVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.network(_testVideoUrl);
      await _videoPlayerController!.initialize();
      
      setState(() {
        _isVideoInitialized = true;
      });
      
      // 循环播放
      _videoPlayerController!.setLooping(true);
    } catch (e) {
      setState(() {
        _isVideoInitialized = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频初始化失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_videoPlayerController == null) return;
    
    if (_videoPlayerController!.value.isPlaying) {
      await _videoPlayerController!.pause();
    } else {
      await _videoPlayerController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画中画功能测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 画中画按钮
          IconButton(
            icon: Icon(isInPiPMode ? Icons.picture_in_picture : Icons.picture_in_picture_alt),
            onPressed: _togglePiP,
            tooltip: isInPiPMode ? '退出画中画' : '进入画中画',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 视频播放区域
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isVideoInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('正在加载测试视频...', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 控制区域
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // 播放控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isVideoInitialized ? _togglePlayback : null,
                        icon: Icon(
                          _videoPlayerController?.value.isPlaying == true 
                              ? Icons.pause 
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _videoPlayerController?.value.isPlaying == true 
                              ? '暂停' 
                              : '播放',
                        ),
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: _isVideoInitialized ? _togglePiP : null,
                        icon: Icon(isInPiPMode ? Icons.picture_in_picture : Icons.picture_in_picture_alt),
                        label: Text(isInPiPMode ? '退出画中画' : '进入画中画'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 画中画状态信息
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '画中画状态',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _buildStatusRow('可用性', isPiPAvailable),
                          _buildStatusRow('当前模式', isInPiPMode ? '画中画' : '正常'),
                          _buildStatusRow('视频状态', _isVideoInitialized ? '已加载' : '未加载'),
                          if (_isVideoInitialized) ...[
                            _buildStatusRow('播放状态', _videoPlayerController!.value.isPlaying ? '播放中' : '已暂停'),
                            _buildStatusRow('视频时长', '${_videoPlayerController!.value.duration.inSeconds}秒'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 说明信息
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用说明',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text('1. 播放视频后，点击"进入画中画"按钮'),  
                          const Text('2. 画中画模式下视频将在小窗口中继续播放'),
                          const Text('3. 点击小窗可返回应用'),
                          const Text('4. 按Home键可自动进入画中画模式'),
                          const Text('5. 在播放器页面中也会自动处理画中画'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// 切换画中画模式
  Future<void> _togglePiP() async {
    if (!_isVideoInitialized) return;
    
    try {
      final success = await togglePiPMode(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        title: '画中画测试',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isInPiPMode ? '已进入画中画模式' : '已退出画中画模式'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画中画模式切换失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画中画模式切换失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}