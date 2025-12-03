import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import '../models/download_task.dart';
import '../models/download_option.dart';
import '../api/video_api.dart';
import 'notification_service.dart';

/// 下载管理器
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  late Box<DownloadTask> _taskBox;
  final List<DownloadTask> _downloadQueue = [];
  DownloadTask? _currentTask;
  Timer? _speedTimer;
  int _lastProgress = 0;

  /// 初始化
  Future<void> initialize() async {
    // 初始化通知服务
    await NotificationService().initialize();
    
    // 请求存储权限
    final permissionGranted = await _requestStoragePermission();
    if (!permissionGranted && Platform.isAndroid) {
      print('警告: 存储权限未授予，下载功能可能受限');
    }
    
    // 打开Hive数据库
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DownloadTaskAdapter());
    }
    _taskBox = await Hive.openBox<DownloadTask>('download_tasks');
    
    // 加载未完成的任务
    await _loadPendingTasks();
    
    // 启动速度计算定时器
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDownloadSpeed();
    });
  }

  /// 加载未完成的任务
  Future<void> _loadPendingTasks() async {
    final tasks = _taskBox.values.where((task) => !task.isCompleted).toList();
    _downloadQueue.clear();
    _downloadQueue.addAll(tasks);
    
    // 如果有等待中的任务，开始下载
    if (_downloadQueue.isNotEmpty && _currentTask == null) {
      _startNextTask();
    }
  }

  /// 添加下载任务
  Future<String> addDownloadTask({
    required String bvid,
    required int cid,
    required String title,
    required String cover,
    String? author,
    required int quality,
    required String qualityName,
    required int partIndex,
    required String partTitle,
    DownloadType downloadType = DownloadType.combined,
  }) async {
    final id = '${bvid}_$cid';
    
    // 检查是否已存在
    final existingTask = _taskBox.get(id);
    if (existingTask != null && !existingTask.isCompleted) {
      throw Exception('任务已存在');
    }

    final task = DownloadTask(
      id: id,
      bvid: bvid,
      cid: cid,
      title: title,
      cover: cover,
      author: author,
      quality: quality,
      qualityName: qualityName,
      partIndex: partIndex,
      partTitle: partTitle,
      createdAt: DateTime.now(),
      downloadType: downloadType,
    );

    await _taskBox.put(id, task);
    _downloadQueue.add(task);
    
    // 如果没有正在下载的任务，开始下载
    if (_currentTask == null) {
      _startNextTask();
    }

    return id;
  }

  /// 开始下一个任务
  void _startNextTask() {
    if (_downloadQueue.isEmpty) {
      _currentTask = null;
      return;
    }

    final task = _downloadQueue.firstWhere(
      (t) => t.status == DownloadStatus.waiting,
      orElse: () => _downloadQueue.first,
    );

    _currentTask = task;
    _downloadTask(task);
  }

  /// 下载任务
  Future<void> _downloadTask(DownloadTask task) async {
    final errorLog = StringBuffer();
    
    try {
      // 发送下载开始通知
      await NotificationService().showDownloadStarted(task.title, task.bvid);
      
      // 更新状态为获取播放地址
      await _updateTaskStatus(task, DownloadStatus.gettingUrl);

      errorLog.writeln('=== 下载任务开始 ===');
      errorLog.writeln('任务ID: ${task.id}');
      errorLog.writeln('视频标题: ${task.title}');
      errorLog.writeln('BVID: ${task.bvid}');
      errorLog.writeln('CID: ${task.cid}');
      errorLog.writeln('画质: ${task.qualityName} (${task.quality})');
      errorLog.writeln('开始时间: ${DateTime.now().toIso8601String()}');
      errorLog.writeln('');

      // 获取播放地址
      errorLog.writeln('正在获取播放地址...');
      final response = await VideoApi.getPlayUrl(
        bvid: task.bvid,
        cid: task.cid,
        qn: task.quality,
      );

      errorLog.writeln('API响应: ${response.toString()}');

      if (response['code'] != 0) {
        final errorMsg = '获取播放地址失败: ${response['message']}';
        errorLog.writeln('错误: $errorMsg');
        throw Exception(errorMsg);
      }

      final data = response['data'];
      String? videoUrl;
      String? audioUrl;
      int totalSize = 0;

      errorLog.writeln('解析播放地址数据...');
      errorLog.writeln('数据结构: ${data.keys.toList()}');

      // 解析播放地址
      if (data['durl'] != null) {
        final durl = data['durl'][0];
        videoUrl = durl['url'];
        totalSize = durl['size'] ?? 0;
        errorLog.writeln('使用MP4/FLV格式');
        errorLog.writeln('视频URL: $videoUrl');
        errorLog.writeln('文件大小: $totalSize bytes');
      } else if (data['dash'] != null) {
        final dash = data['dash'];
        errorLog.writeln('使用DASH格式');
        if (dash['video'] != null) {
          final videos = dash['video'] as List;
          if (videos.isNotEmpty) {
            videoUrl = videos[0]['baseUrl'] ?? videos[0]['base_url'];
            errorLog.writeln('视频流: $videoUrl');
          }
        }
        if (dash['audio'] != null) {
          final audios = dash['audio'] as List;
          if (audios.isNotEmpty) {
            audioUrl = audios[0]['baseUrl'] ?? audios[0]['base_url'];
            errorLog.writeln('音频流: $audioUrl');
          }
        }
      }

      if (videoUrl == null) {
        final errorMsg = '无法获取视频播放地址';
        errorLog.writeln('错误: $errorMsg');
        errorLog.writeln('可用数据: $data');
        throw Exception(errorMsg);
      }

      // 更新任务信息
      final updatedTask = task.copyWith(
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        totalSize: totalSize,
        status: DownloadStatus.downloading,
      );
      await _taskBox.put(task.id, updatedTask);
      _currentTask = updatedTask;

      // 创建下载目录
      errorLog.writeln('创建下载目录...');
      final directory = await _getDownloadDirectory();
      final downloadDir = Directory('${directory.path}/${task.bvid}');
      errorLog.writeln('下载目录: ${downloadDir.path}');
      
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
        errorLog.writeln('目录创建成功');
      } else {
        errorLog.writeln('目录已存在');
      }

      String? finalSavePath;
      
      // 根据下载类型决定下载内容
      switch (task.downloadType) {
        case DownloadType.videoOnly:
          // 仅下载视频
          final videoFileName = '${task.partIndex + 1}_${task.qualityName}_video.mp4';
          final videoPath = '${downloadDir.path}/$videoFileName';
          errorLog.writeln('开始下载视频文件: $videoFileName');
          errorLog.writeln('保存路径: $videoPath');
          
          await _downloadFile(
            url: videoUrl!,
            savePath: videoPath,
            task: updatedTask,
            errorLog: errorLog,
          );
          finalSavePath = videoPath;
          break;
          
        case DownloadType.audioOnly:
          // 仅下载音频
          if (audioUrl == null) {
            throw Exception('音频流不可用，无法仅下载音频');
          }
          await _updateTaskStatus(updatedTask, DownloadStatus.downloadingAudio);
          
          final audioFileName = '${task.partIndex + 1}_${task.qualityName}_audio.m4a';
          final audioPath = '${downloadDir.path}/$audioFileName';
          errorLog.writeln('开始下载音频文件: $audioFileName');
          errorLog.writeln('保存路径: $audioPath');
          
          await _downloadFile(
            url: audioUrl,
            savePath: audioPath,
            task: updatedTask,
            isAudio: true,
            errorLog: errorLog,
          );
          finalSavePath = audioPath;
          break;
          
        case DownloadType.combined:
          // 下载音视频合并
          final videoFileName = '${task.partIndex + 1}_${task.qualityName}.mp4';
          final videoPath = '${downloadDir.path}/$videoFileName';
          errorLog.writeln('开始下载视频文件: $videoFileName');
          errorLog.writeln('保存路径: $videoPath');
          
          await _downloadFile(
            url: videoUrl!,
            savePath: videoPath,
            task: updatedTask,
            errorLog: errorLog,
          );

          // 如果有音频，下载音频文件
          if (audioUrl != null) {
            errorLog.writeln('开始下载音频文件...');
            await _updateTaskStatus(updatedTask, DownloadStatus.downloadingAudio);
            
            final audioFileName = '${task.partIndex + 1}_audio.m4a';
            final audioPath = '${downloadDir.path}/$audioFileName';
            errorLog.writeln('音频文件名: $audioFileName');
            errorLog.writeln('音频保存路径: $audioPath');
            
            await _downloadFile(
              url: audioUrl,
              savePath: audioPath,
              task: updatedTask,
              isAudio: true,
              errorLog: errorLog,
            );
          }
          finalSavePath = videoPath;
          break;
      }

      // 标记完成
      errorLog.writeln('下载完成!');
      errorLog.writeln('完成时间: ${DateTime.now().toIso8601String()}');
      await _updateTaskStatus(updatedTask, DownloadStatus.completed, savePath: finalSavePath);
      
      // 发送完成通知
      await NotificationService().showDownloadCompleted(task.title, task.bvid, finalSavePath ?? '');

    } catch (e, stackTrace) {
      errorLog.writeln('');
      errorLog.writeln('=== 下载失败 ===');
      errorLog.writeln('错误类型: ${e.runtimeType}');
      errorLog.writeln('错误信息: $e');
      errorLog.writeln('堆栈跟踪:');
      errorLog.writeln(stackTrace.toString());
      errorLog.writeln('失败时间: ${DateTime.now().toIso8601String()}');
      
      await _updateTaskStatus(
        task, 
        DownloadStatus.failed, 
        errorMessage: e.toString(),
        errorLog: errorLog.toString(),
      );
      
      // 发送失败通知
      await NotificationService().showDownloadFailed(task.title, task.bvid, e.toString());
    }

    // 继续下一个任务
    await Future.delayed(const Duration(seconds: 1));
    _startNextTask();
  }

  /// 下载文件
  Future<void> _downloadFile({
    required String url,
    required String savePath,
    required DownloadTask task,
    bool isAudio = false,
    StringBuffer? errorLog,
  }) async {
    final file = File(savePath);
    int downloadedLength = 0;

    // 检查是否支持断点续传
    if (await file.exists()) {
      downloadedLength = await file.length();
      errorLog?.writeln('${isAudio ? "音频" : "视频"}文件已存在，大小: $downloadedLength bytes');
      
      // 如果文件已完整下载，跳过
      if (task.totalSize > 0 && downloadedLength >= task.totalSize) {
        errorLog?.writeln('${isAudio ? "音频" : "视频"}文件已完整下载，跳过');
        return;
      }
    }

    try {
      errorLog?.writeln('开始下载${isAudio ? "音频" : "视频"}文件...');
      errorLog?.writeln('下载URL: $url');
      errorLog?.writeln('Range: ${downloadedLength > 0 ? "bytes=$downloadedLength-" : "完整下载"}');
      
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (!isAudio) {
            _updateTaskProgress(task, downloadedLength + received);
            
            // 更新进度通知
            if (total > 0) {
              final progress = ((downloadedLength + received) / total * 100).round();
              NotificationService().showDownloadProgress(task.title, task.bvid, progress);
            }
          }
          
          // 每10MB记录一次进度
          if (received % (10 * 1024 * 1024) == 0) {
            errorLog?.writeln('下载进度: ${received}/${total} bytes (${((received / total) * 100).toStringAsFixed(1)}%)');
          }
        },
        options: Options(
          headers: {
            if (downloadedLength > 0) 'Range': 'bytes=$downloadedLength-',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      errorLog?.writeln('${isAudio ? "音频" : "视频"}下载完成: $savePath');
    } catch (e, stackTrace) {
      errorLog?.writeln('');
      errorLog?.writeln('=== ${isAudio ? "音频" : "视频"}下载失败 ===');
      errorLog?.writeln('错误类型: ${e.runtimeType}');
      errorLog?.writeln('错误信息: $e');
      if (e is DioException) {
        errorLog?.writeln('HTTP状态码: ${e.response?.statusCode}');
        errorLog?.writeln('响应头: ${e.response?.headers}');
        errorLog?.writeln('请求URL: ${e.requestOptions.uri}');
        errorLog?.writeln('请求方法: ${e.requestOptions.method}');
        errorLog?.writeln('请求头: ${e.requestOptions.headers}');
      }
      errorLog?.writeln('堆栈跟踪:');
      errorLog?.writeln(stackTrace.toString());
      rethrow;
    }
  }

  /// 更新任务状态
  Future<void> _updateTaskStatus(
    DownloadTask task,
    DownloadStatus status, {
    String? errorMessage,
    String? errorLog,
    String? savePath,
  }) async {
    final updatedTask = task.copyWith(
      status: status,
      errorMessage: errorMessage,
      errorLog: errorLog,
      savePath: savePath,
    );
    
    await _taskBox.put(task.id, updatedTask);
    
    // 更新当前任务引用
    if (_currentTask?.id == task.id) {
      _currentTask = updatedTask;
    }
    
    // 更新队列中的任务
    final queueIndex = _downloadQueue.indexWhere((t) => t.id == task.id);
    if (queueIndex != -1) {
      _downloadQueue[queueIndex] = updatedTask;
    }
  }

  /// 更新任务进度
  Future<void> _updateTaskProgress(DownloadTask task, int progress) async {
    final updatedTask = task.copyWith(progress: progress);
    await _taskBox.put(task.id, updatedTask);
    
    // 更新当前任务引用
    if (_currentTask?.id == task.id) {
      _currentTask = updatedTask;
      _lastProgress = progress;
    }
    
    // 更新队列中的任务
    final queueIndex = _downloadQueue.indexWhere((t) => t.id == task.id);
    if (queueIndex != -1) {
      _downloadQueue[queueIndex] = updatedTask;
    }
  }

  /// 更新下载速度
  void _updateDownloadSpeed() {
    if (_currentTask != null && _currentTask!.isDownloading) {
      final currentProgress = _currentTask!.progress;
      final speed = (currentProgress - _lastProgress).toDouble();
      
      final updatedTask = _currentTask!.copyWith(speed: speed);
      _taskBox.put(_currentTask!.id, updatedTask);
      _currentTask = updatedTask;
      
      // 更新队列中的任务
      final queueIndex = _downloadQueue.indexWhere((t) => t.id == _currentTask!.id);
      if (queueIndex != -1) {
        _downloadQueue[queueIndex] = updatedTask;
      }
      
      _lastProgress = currentProgress;
    }
  }

  /// 暂停任务
  Future<void> pauseTask(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null && task.canPause) {
      await _updateTaskStatus(task, DownloadStatus.paused);
    }
  }

  /// 恢复任务
  Future<void> resumeTask(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null && task.canResume) {
      await _updateTaskStatus(task, DownloadStatus.waiting);
      
      // 如果没有正在下载的任务，开始下载
      if (_currentTask == null) {
        _startNextTask();
      }
    }
  }

  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null && task.canCancel) {
      await _updateTaskStatus(task, DownloadStatus.cancelled);
      
      // 如果是当前任务，停止下载并开始下一个
      if (_currentTask?.id == taskId) {
        _currentTask = null;
        _startNextTask();
      }
      
      // 从队列中移除
      _downloadQueue.removeWhere((t) => t.id == taskId);
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await cancelTask(taskId);
    await _taskBox.delete(taskId);
    _downloadQueue.removeWhere((t) => t.id == taskId);
    
    // 删除文件
    final task = _taskBox.get(taskId);
    if (task?.savePath != null) {
      try {
        final file = File(task!.savePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('删除文件失败: $e');
      }
    }
  }

  /// 获取所有任务
  List<DownloadTask> getAllTasks() {
    return _taskBox.values.toList();
  }

  /// 获取当前任务
  DownloadTask? getCurrentTask() {
    return _currentTask;
  }

  /// 获取等待中的任务数量
  int getWaitingCount() {
    return _downloadQueue.where((t) => t.status == DownloadStatus.waiting).length;
  }

  /// 获取下载中的任务数量
  int getDownloadingCount() {
    return _downloadQueue.where((t) => t.isDownloading).length;
  }

  /// 获取下载路径信息
  Future<String> getDownloadPathInfo() async {
    final directory = await _getDownloadDirectory();
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidInfo();
      final sdkInt = androidInfo['version']['sdkInt'] as int? ?? 30;
      
      String pathType = '';
      if (sdkInt >= 34 && directory.path.contains('/Download/')) {
        pathType = 'Android 14+ 系统下载目录';
      } else if (sdkInt >= 34 && directory.path.contains('biliownxdownloads')) {
        pathType = 'Android 14+ 自定义目录';
      } else if (sdkInt >= 29 && directory.path.contains('biliownxdownloads')) {
        pathType = 'Android 10+ 外部存储';
      } else if (directory.path.contains('/storage/emulated/0/')) {
        pathType = 'Android 外部存储';
      } else {
        pathType = 'Android 内部存储';
      }
      
      return '$pathType: ${directory.path}';
    } else {
      return '${Platform.operatingSystem}: ${directory.path}';
    }
  }

  /// 清理已完成的任务
  Future<void> clearCompletedTasks() async {
    final completedTasks = _taskBox.values.where((t) => t.isCompleted).toList();
    for (final task in completedTasks) {
      await _taskBox.delete(task.id);
    }
  }

  /// 释放资源
  void dispose() {
    _speedTimer?.cancel();
    _taskBox.close();
  }

  /// 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        // 获取 Android SDK 版本
        final androidInfo = await _getAndroidInfo();
        final sdkInt = androidInfo['version.sdkInt'] as int? ?? 30;
        
        print('Android SDK 版本: $sdkInt');
        
        // Android 14+ 需要通知权限
        if (sdkInt >= 34) {
          await _requestNotificationPermission();
        }
        
        // Android 15+ 需要部分访问媒体权限
        if (sdkInt >= 35) {
          await _requestPartialMediaPermission();
        }
        
        // Android 13+ (API 33) 使用媒体权限替代存储权限
        if (sdkInt >= 33) {
          return await _requestMediaPermissions();
        }
        
        // Android 10-12 使用传统存储权限
        if (sdkInt >= 29) {
          return await _requestLegacyStoragePermissions();
        }
        
        // Android 9 及以下使用基础存储权限
        return await _requestBasicStoragePermission();
        
      } catch (e) {
        print('请求权限时出错: $e');
        return false;
      }
    }
    return true; // 非 Android 平台不需要特殊权限
  }

  /// 请求通知权限 (Android 14+)
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        print('通知权限已授予');
      } else {
        print('通知权限被拒绝，将无法显示下载进度通知');
      }
    }
  }

  /// 请求部分访问媒体权限 (Android 15+)
  Future<void> _requestPartialMediaPermission() async {
    if (await Permission.photos.isDenied) {
      final result = await Permission.photos.request();
      if (result.isGranted) {
        print('照片访问权限已授予');
      } else {
        print('照片访问权限被拒绝');
      }
    }
  }

  /// 请求媒体权限 (Android 13+)
  Future<bool> _requestMediaPermissions() async {
    bool hasPermission = true;
    
    // 请求视频权限
    if (await Permission.videos.isDenied) {
      final result = await Permission.videos.request();
      if (!result.isGranted) {
        print('视频访问权限被拒绝');
        hasPermission = false;
      }
    }
    
    // 请求音频权限
    if (await Permission.audio.isDenied) {
      final result = await Permission.audio.request();
      if (!result.isGranted) {
        print('音频访问权限被拒绝');
        hasPermission = false;
      }
    }
    
    return hasPermission;
  }

  /// 请求传统存储权限 (Android 10-12)
  Future<bool> _requestLegacyStoragePermissions() async {
    bool hasPermission = true;
    
    // 基础存储权限
    if (await Permission.storage.isDenied) {
      final result = await Permission.storage.request();
      if (!result.isGranted) {
        print('存储权限被拒绝');
        hasPermission = false;
      }
    }
    
    // 管理外部存储权限 (Android 11+)
    if (await Permission.manageExternalStorage.isDenied) {
      final result = await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        print('管理外部存储权限被拒绝，将使用内部存储');
        // 这个权限不是必需的，可以继续使用内部存储
      }
    }
    
    return hasPermission;
  }

  /// 请求基础存储权限 (Android 9 及以下)
  Future<bool> _requestBasicStoragePermission() async {
    if (await Permission.storage.isDenied) {
      final result = await Permission.storage.request();
      if (!result.isGranted) {
        print('存储权限被拒绝');
        return false;
      }
    }
    return true;
  }

  /// 获取 Android 系统信息
  Future<Map<String, dynamic>> _getAndroidInfo() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return {
        'version': {
          'sdkInt': androidInfo.version.sdkInt,
          'release': androidInfo.version.release,
        },
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
      };
    } catch (e) {
      print('获取 Android 信息失败: $e');
      return {'version': {'sdkInt': 30}};
    }
  }

  /// 获取下载目录
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await _getAndroidInfo();
        final sdkInt = androidInfo['version']['sdkInt'] as int? ?? 30;
        
        print('Android SDK: $sdkInt, 获取下载目录...');
        
        // Android 14+ (API 34+) 优先使用 Downloads 目录
        if (sdkInt >= 34) {
          final downloadsDir = await _getAndroid14DownloadDirectory();
          if (downloadsDir != null) {
            return downloadsDir;
          }
        }
        
        // Android 10+ (API 29+) 使用外部存储
        if (sdkInt >= 29) {
          final externalDir = await _getModernAndroidDownloadDirectory();
          if (externalDir != null) {
            return externalDir;
          }
        }
        
        // Android 9 及以下使用传统方法
        final legacyDir = await _getLegacyAndroidDownloadDirectory();
        if (legacyDir != null) {
          return legacyDir;
        }
        
      } catch (e) {
        print('获取 Android 下载目录失败: $e');
      }
      
      // 最终备选方案：使用内部存储
      return await _getInternalDownloadDirectory();
      
    } else {
      // 非 Android 平台使用应用文档目录
      return await _getNonAndroidDownloadDirectory();
    }
  }

  /// Android 14+ 下载目录 (优先使用系统 Downloads 目录)
  Future<Directory?> _getAndroid14DownloadDirectory() async {
    try {
      // 尝试访问系统 Downloads 目录
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final appDownloadDir = Directory('${downloadsDir.path}/BiliOwnx');
      
      if (!await appDownloadDir.exists()) {
        await appDownloadDir.create(recursive: true);
      }
      
      print('Android 14+ 使用系统 Downloads 目录: ${appDownloadDir.path}');
      return appDownloadDir;
    } catch (e) {
      print('无法访问系统 Downloads 目录: $e');
      return null;
    }
  }

  /// Android 10+ 下载目录
  Future<Directory?> _getModernAndroidDownloadDirectory() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // 从 /storage/emulated/0/Android/data/package.name/files
        // 提取基础路径 /storage/emulated/0/
        final basePath = externalDir.path.split('Android')[0];
        final customDownloadDir = Directory('${basePath}biliownxdownloads');
        
        if (!await customDownloadDir.exists()) {
          await customDownloadDir.create(recursive: true);
        }
        
        print('Android 10+ 使用自定义目录: ${customDownloadDir.path}');
        return customDownloadDir;
      }
    } catch (e) {
      print('获取现代 Android 下载目录失败: $e');
      return null;
    }
    return null;
  }

  /// Android 9 及以下下载目录
  Future<Directory?> _getLegacyAndroidDownloadDirectory() async {
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadDir = Directory('${externalDir.path}/downloads');
        
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        
        print('Android 9- 使用传统目录: ${downloadDir.path}');
        return downloadDir;
      }
    } catch (e) {
      print('获取传统 Android 下载目录失败: $e');
      return null;
    }
    return null;
  }

  /// 内部存储备选目录
  Future<Directory> _getInternalDownloadDirectory() async {
    final internalDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${internalDir.path}/downloads');
    
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    
    print('使用内部存储备选目录: ${fallbackDir.path}');
    return fallbackDir;
  }

  /// 非 Android 平台下载目录
  Future<Directory> _getNonAndroidDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/downloads');
    
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    
    return downloadDir;
  }
}

/// Hive适配器
class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final typeId = 0;

  @override
  DownloadTask read(BinaryReader reader) {
    return DownloadTask.fromJson(Map<String, dynamic>.from(reader.read()));
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer.write(obj.toJson());
  }
}