/// 下载任务状态
enum DownloadStatus {
  waiting,        // 等待中
  gettingUrl,     // 获取播放地址
  downloading,    // 下载中
  downloadingAudio, // 下载音频
  gettingDanmaku, // 获取弹幕
  completed,      // 完成
  paused,         // 暂停
  failed,         // 失败
  cancelled,      // 已取消
}

/// 下载任务
class DownloadTask {
  final String id;
  final String bvid;
  final int cid;
  final String title;
  final String cover;
  final String? author;
  final int quality;
  final String qualityName;
  final int partIndex;
  final String partTitle;
  final DateTime createdAt;
  
  DownloadStatus status;
  int progress;      // 已下载字节数
  int totalSize;     // 总字节数
  double speed;      // 下载速度 (bytes/s)
  String? errorMessage;
  String? errorLog;     // 详细错误日志
  String? savePath;
  String? videoUrl;
  String? audioUrl;
  String? danmakuUrl;
  
  DownloadTask({
    required this.id,
    required this.bvid,
    required this.cid,
    required this.title,
    required this.cover,
    this.author,
    required this.quality,
    required this.qualityName,
    required this.partIndex,
    required this.partTitle,
    required this.createdAt,
    this.status = DownloadStatus.waiting,
    this.progress = 0,
    this.totalSize = 0,
    this.speed = 0,
    this.errorMessage,
    this.errorLog,
    this.savePath,
    this.videoUrl,
    this.audioUrl,
    this.danmakuUrl,
  });

  /// 创建副本
  DownloadTask copyWith({
    String? id,
    String? bvid,
    int? cid,
    String? title,
    String? cover,
    String? author,
    int? quality,
    String? qualityName,
    int? partIndex,
    String? partTitle,
    DateTime? createdAt,
    DownloadStatus? status,
    int? progress,
    int? totalSize,
    double? speed,
    String? errorMessage,
    String? errorLog,
    String? savePath,
    String? videoUrl,
    String? audioUrl,
    String? danmakuUrl,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      author: author ?? this.author,
      quality: quality ?? this.quality,
      qualityName: qualityName ?? this.qualityName,
      partIndex: partIndex ?? this.partIndex,
      partTitle: partTitle ?? this.partTitle,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalSize: totalSize ?? this.totalSize,
      speed: speed ?? this.speed,
      errorMessage: errorMessage ?? this.errorMessage,
      errorLog: errorLog ?? this.errorLog,
      savePath: savePath ?? this.savePath,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      danmakuUrl: danmakuUrl ?? this.danmakuUrl,
    );
  }

  /// 获取状态文本
  String get statusText {
    switch (status) {
      case DownloadStatus.waiting:
        return '等待中';
      case DownloadStatus.gettingUrl:
        return '获取播放地址';
      case DownloadStatus.downloading:
        if (totalSize > 0) {
          final progressPercent = (progress / totalSize * 100).toStringAsFixed(1);
          return '下载中 $progressPercent%';
        }
        return '下载中';
      case DownloadStatus.downloadingAudio:
        return '下载音频';
      case DownloadStatus.gettingDanmaku:
        return '获取弹幕';
      case DownloadStatus.completed:
        return '下载完成';
      case DownloadStatus.paused:
        return '已暂停';
      case DownloadStatus.failed:
        return '下载失败';
      case DownloadStatus.cancelled:
        return '已取消';
    }
  }

  /// 获取进度百分比
  double get progressPercent {
    if (totalSize <= 0) return 0.0;
    return progress / totalSize;
  }

  /// 是否正在下载
  bool get isDownloading {
    return status == DownloadStatus.downloading || 
           status == DownloadStatus.downloadingAudio ||
           status == DownloadStatus.gettingUrl ||
           status == DownloadStatus.gettingDanmaku;
  }

  /// 是否已完成
  bool get isCompleted {
    return status == DownloadStatus.completed;
  }

  /// 是否可以暂停
  bool get canPause {
    return status == DownloadStatus.downloading || 
           status == DownloadStatus.downloadingAudio;
  }

  /// 是否可以恢复
  bool get canResume {
    return status == DownloadStatus.paused || 
           status == DownloadStatus.failed;
  }

  /// 是否可以取消
  bool get canCancel {
    return status != DownloadStatus.completed && 
           status != DownloadStatus.cancelled;
  }

  /// 获取显示名称
  String get displayName {
    if (partTitle.isNotEmpty) {
      return '$title - $partTitle';
    }
    return title;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bvid': bvid,
      'cid': cid,
      'title': title,
      'cover': cover,
      'author': author,
      'quality': quality,
      'qualityName': qualityName,
      'partIndex': partIndex,
      'partTitle': partTitle,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.index,
      'progress': progress,
      'totalSize': totalSize,
      'speed': speed,
      'errorMessage': errorMessage,
      'errorLog': errorLog,
      'savePath': savePath,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'danmakuUrl': danmakuUrl,
    };
  }

  /// 从JSON创建
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'],
      bvid: json['bvid'],
      cid: json['cid'],
      title: json['title'],
      cover: json['cover'],
      author: json['author'],
      quality: json['quality'],
      qualityName: json['qualityName'],
      partIndex: json['partIndex'],
      partTitle: json['partTitle'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      status: DownloadStatus.values[json['status']],
      progress: json['progress'],
      totalSize: json['totalSize'],
      speed: json['speed'],
      errorMessage: json['errorMessage'],
      errorLog: json['errorLog'],
      savePath: json['savePath'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      danmakuUrl: json['danmakuUrl'],
    );
  }
}