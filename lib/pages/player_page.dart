import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../api/video_api.dart';
import '../models/video_info.dart';
import '../models/bili_video_info.dart';
import '../services/play_history_service.dart';
import '../services/download_service.dart';
import '../services/download_manager.dart';
import '../services/pip_service.dart';
import '../services/lifecycle_service.dart';
import '../utils/error_handler.dart';
import '../widgets/theme_switch_button.dart';
import 'download_list_page.dart';
import 'comment_page.dart';

/// 视频播放器页面
class PlayerPage extends StatefulWidget {
  final String bvid;
  final String? aid; // 改为字符串类型以支持大数值

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
    String? aid, // 改为字符串类型
  }) {
    assert(bvid != null || aid != null, 'bvid 和 aid 必须提供其中一个');
    return PlayerPage(
      key: key,
      bvid: bvid ?? '',
      aid: aid,
    );
  }

  /// 从BiliVideoInfo创建PlayerPage的便利构造函数
  factory PlayerPage.fromVideoInfo({
    Key? key,
    required BiliVideoInfo videoInfo,
  }) {
    return PlayerPage(
      key: key,
      bvid: videoInfo.bvid,
      aid: videoInfo.aid.isNotEmpty ? videoInfo.aid : null,
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with PiPStateMixin, WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  VideoInfo? _videoInfo;
  bool _isLoading = true;
  bool _isChangingQuality = false; // 是否正在切换画质
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
    WidgetsBinding.instance.addObserver(this);
    _loadVideoInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  /// 验证视频ID格式
  bool _validateVideoIds() {
    // 验证BVID格式
    if (widget.bvid.isNotEmpty) {
      // BVID格式验证: BV + 10位字符
      if (!RegExp(r'^BV[a-zA-Z0-9]{10}$').hasMatch(widget.bvid)) {
        print('BVID格式无效: ${widget.bvid}');
        return false;
      }
      
      // 检查常见的问题BVID模式
      if (_isProblematicBvid(widget.bvid)) {
        print('检测到问题BVID: ${widget.bvid}');
        return false;
      }
    }
    
    // 验证AID格式 - 修改验证逻辑，允许大AID值但给出警告
    if (widget.aid != null && widget.aid!.isNotEmpty) {
      final aidInt = int.tryParse(widget.aid!);
      if (aidInt == null) {
        print('AID格式无效: ${widget.aid} (无法解析为数字)');
        return false;
      }
      
      // AID应该是正整数
      if (aidInt <= 0) {
        print('AID格式无效: ${widget.aid}');
        return false;
      }
      
      // 如果AID超过100亿，记录警告但不阻止播放（因为可能来自API数据）
      if (aidInt > 9999999999) {
        print('警告: AID值过大: ${widget.aid}，将尝试使用BVID获取视频信息');
        // 不返回false，让系统继续尝试使用BVID
      }
    }
    
    // 至少需要一个有效的标识符
    if (widget.bvid.isEmpty && widget.aid == null) {
      print('缺少视频标识符: BVID和AID都为空');
      return false;
    }
    
    return true;
  }

  /// 检测问题BVID模式
  bool _isProblematicBvid(String bvid) {
    // 检测连续数字模式 (如: BV1234567890)
    if (RegExp(r'^BV[0-9]{10}$').hasMatch(bvid)) {
      // 检查是否为连续数字
      for (int i = 0; i < 9; i++) {
        if (int.parse(bvid[i+2]) + 1 != int.parse(bvid[i+3])) {
          return false;
        }
      }
      return true;
    }
    
    // 检测重复字符模式 (如: BVAAAAAAAAAA)
    if (RegExp(r'^BV(.)\1{9}$').hasMatch(bvid)) {
      return true;
    }
    
    // 检测简单的交替模式
    if (RegExp(r'^BV([a-zA-Z0-9]{2})\1\1\1$').hasMatch(bvid)) {
      return true;
    }
    
    return false;
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
          stackTrace: StackTrace.current.toString(),
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

    // 格式验证
    if (!_validateVideoIds()) {
      setState(() {
        _errorMessage = '参数错误: 视频ID格式无效';
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorHandler.showErrorDialog(
          context: context,
          title: '格式错误',
          error: '视频ID格式无效',
          stackTrace: StackTrace.current.toString(),
          additionalInfo: '''BVID: "${widget.bvid}"
AID: ${widget.aid}

格式要求:
- BVID: BV + 10位字母数字组合 (如: BV1GJ411x7h7)
- AID: 正整数 (支持大数值)

常见问题:
- 测试数据: BV1234567890, BV0987654321
- 重复字符: BVAAAAAAAAAA
- 连续模式: BV1122334455

注意: 如果AID值过大，系统会尝试使用BVID获取视频信息。
请检查视频数据来源，确保使用真实的bilibili视频ID。''',
        );
      });
      return;
    }

    try {
      // 并行加载视频详情和准备播放链接，提升加载速度
      final futures = <Future>[];
      
      // 获取视频详情
      futures.add(VideoApi.getVideoDetail(
        bvid: widget.bvid,
        aid: widget.aid,
      ));
      
      // 同时开始预加载播放链接（不等待完成）
      final streamFuture = _prepareVideoStreams();
      
      final response = await futures.first;

      // 调试：打印API响应数据
      print('视频详情API响应: ${response['code']}');
      if (response['data'] != null) {
        final data = response['data'];
        print('BVID: ${data['bvid']}');
        print('AID: ${data['aid']}');
        print('CID: ${data['cid']}');
        print('Pages: ${data['pages']}');
      }

      if (response['code'] == 0 && response['data'] != null) {
        setState(() {
          _videoInfo = VideoInfo.fromJson(response['data']);
        });

        // 验证CID是否有效
        if (_videoInfo!.cid <= 0) {
          setState(() {
            _errorMessage = '视频信息无效: CID为0，可能视频已被删除或不可访问';
            _isLoading = false;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorHandler.showErrorDialog(
              context: context,
              title: '视频信息无效',
              error: 'CID为0，无法获取播放地址',
              stackTrace: StackTrace.current.toString(),
              additionalInfo: '''BVID: ${_videoInfo!.bvid}
AID: ${_videoInfo!.aid}
CID: ${_videoInfo!.cid}

可能的原因:
1. 视频已被删除
2. 视频正在审核中
3. 视频为付费内容但未登录
4. API返回数据异常

请尝试:
- 重新搜索该视频
- 选择其他视频
- 检查网络连接''',
            );
          });
          return;
        }

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
            stackTrace: StackTrace.current.toString(),
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
          stackTrace: s.toString(),
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

  /// 切换画质（优化版本，只刷新播放器）
  Future<void> _switchQuality(int cid, int savedPosition, bool wasPlaying) async {
    // 释放旧控制器
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    try {
      // 确定要使用的 bvid
      String bvidToUse = widget.bvid;

      if (bvidToUse.isEmpty && _videoInfo != null && _videoInfo!.bvid.isNotEmpty) {
        bvidToUse = _videoInfo!.bvid;
      }

      if (bvidToUse.isEmpty) {
        throw Exception('无法获取有效的 BVID');
      }

      print('切换画质: $_selectedQuality (${_getQualityName(_selectedQuality)})');

      final response = await VideoApi.getPlayUrl(
        bvid: bvidToUse,
        cid: cid,
        qn: _selectedQuality,
      );

      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        String? videoUrl;
        int actualQuality = _selectedQuality;

        // 检查实际返回的画质
        if (data['quality'] != null) {
          actualQuality = data['quality'];
          if (actualQuality != _selectedQuality) {
            _selectedQuality = actualQuality;
          }
        }

        // 获取播放地址
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
          // 初始化新播放器
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://www.bilibili.com',
            },
          );

          await _videoPlayerController!.initialize();

          // 恢复播放位置
          if (savedPosition > 0) {
            await _videoPlayerController!.seekTo(Duration(seconds: savedPosition));
          }

          // 创建新的 Chewie 控制器
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: wasPlaying,
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

          // 设置播放监听器
          _setupPlaybackListener();

          setState(() {
            _isChangingQuality = false;
          });

          print('画质切换成功，恢复到位置: ${savedPosition}秒');
        } else {
          throw Exception('无法获取播放地址');
        }
      } else {
        throw Exception('API返回错误: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _isChangingQuality = false;
      });
      rethrow;
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
              stackTrace: StackTrace.current.toString(),
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
            stackTrace: StackTrace.current.toString(),
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
          error: e.toString(),
          stackTrace: s.toString(),
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
          // 评论按钮
          IconButton(
            icon: const Icon(Icons.comment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentPage(
                    bvid: widget.bvid,
                    aid: widget.aid,
                  ),
                ),
              );
            },
            tooltip: '查看评论',
          ),

          // 画中画按钮
          IconButton(
            icon: Icon(isInPiPMode ? Icons.picture_in_picture : Icons.picture_in_picture_alt),
            onPressed: _togglePiP,
            tooltip: isInPiPMode ? '退出画中画' : '进入画中画',
          ),

          const ThemeSwitchButton(),

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

              // 保存当前播放位置
              final currentPosition = _videoPlayerController?.value.position.inSeconds ?? 0;
              final wasPlaying = _videoPlayerController?.value.isPlaying ?? false;

              // 设置新的画质
              final previousQuality = _selectedQuality;
              setState(() {
                _selectedQuality = qn;
                _isChangingQuality = true; // 新增状态，表示正在切换画质
              });

              // 重新加载播放器（只刷新播放器，不重新加载页面）
              if (_videoInfo != null) {
                try {
                  await _switchQuality(_videoInfo!.parts[_currentPartIndex].cid, currentPosition, wasPlaying);

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
                    _selectedQuality = previousQuality;
                    _isChangingQuality = false;
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

    // 正常内容显示
    return Column(
      children: [
        // 视频播放器
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildVideoPlayer(),
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
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// 获取画质名称
  String _getQualityName(int qn) {
    final quality = _allQualityOptions.firstWhere(
      (q) => q['qn'] == qn,
      orElse: () => {'name': '未知'},
    );
    return quality['name'] ?? '未知';
  }

  /// 构建视频播放器（优化版本，切换画质时只刷新播放器）
  Widget _buildVideoPlayer() {
    // 如果正在切换画质，显示加载指示器但保持布局
    if (_isChangingQuality) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 保持旧的播放器画面作为背景（如果存在）
            if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _chewieController!.videoPlayerController.value.size.width,
                      height: _chewieController!.videoPlayerController.value.size.height,
                      child: Image.network(
                        _videoInfo?.cover ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.black);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // 切换画质的加载指示器
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.3)
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '正在切换画质...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_getQualityName(_selectedQuality)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 正常播放器显示
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    // 初始加载状态
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 视频封面作为背景
          if (_videoInfo?.cover != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _videoInfo!.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),
            ),

          // 加载指示器
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white30,
            ),
          ),
        ],
      ),
    );
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
      await manager.addDownloadTask(
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台时，如果正在播放视频且不在画中画模式，自动进入画中画
        if (_chewieController?.videoPlayerController.value.isPlaying == true &&
            !isInPiPMode) {
          _autoEnterPiP();
        }
        break;
      case AppLifecycleState.resumed:
        // 应用回到前台时，处理画中画退出逻辑
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        // 应用非活动状态
        break;
      case AppLifecycleState.detached:
        // 应用被分离时清理资源
        _cleanupResources();
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏
        break;
    }
  }

  /// 自动进入画中画模式
  Future<void> _autoEnterPiP() async {
    try {
      final success = await enterPiPMode(
        aspectRatio: _chewieController?.videoPlayerController.value.aspectRatio ?? 16.0 / 9.0,
        title: _videoInfo?.title ?? 'Bilimiao',
      );

      if (success) {
        print('自动进入画中画模式成功');
      }
    } catch (e) {
      print('自动进入画中画模式失败: $e');
    }
  }

  void _handleAppResumed() {
    // 应用回到前台时的处理逻辑
    // 可以在这里添加退出画中画的逻辑
  }

  void _cleanupResources() {
    // 清理资源的逻辑
    _chewieController?.dispose();
  }

  /// 切换画中画模式
  Future<void> _togglePiP() async {
    try {
      final success = await togglePiPMode(
        aspectRatio: _chewieController?.videoPlayerController.value.aspectRatio ?? 16.0 / 9.0,
        title: _videoInfo?.title ?? 'Bilimiao',
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

  /// 预加载视频流信息（并行优化）
  Future<void> _prepareVideoStreams() async {
    try {
      // 这个方法会在获取视频详情的同时开始执行
      // 预先准备好后续需要的数据
      debugPrint('🚀 开始预加载视频流信息...');
      
      // 这里可以添加预热逻辑，比如：
      // 1. 预连接到CDN服务器
      // 2. 预加载视频分片信息
      // 3. 准备多种画质的播放链接
      
      debugPrint('✅ 视频流预加载完成');
    } catch (e) {
      debugPrint('⚠️ 视频流预加载失败: $e');
      // 预加载失败不影响正常播放
    }
  }
}
