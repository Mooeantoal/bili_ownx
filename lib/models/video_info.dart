/// 视频信息模型
class VideoInfo {
  final String bvid;
  final String aid; // 改为字符串类型以支持大数值
  final String title;
  final String desc;
  final String cover;
  final String author;
  final int duration;
  final int cid; // 默认第一P的cid
  final List<VideoPart> parts; // 分P列表
  
  // 添加缺失的字段
  final String description;
  final List<String> tags;
  final DateTime publishDate;
  final int viewCount;
  final int likeCount;
  final int coinCount;
  final int favoriteCount;
  final int shareCount;
  final String durationStr;
  final List<VideoQuality> qualities;

  VideoInfo({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.desc,
    required this.cover,
    required this.author,
    required this.duration,
    required this.cid,
    required this.parts,
    required this.description,
    required this.tags,
    required this.publishDate,
    required this.viewCount,
    required this.likeCount,
    required this.coinCount,
    required this.favoriteCount,
    required this.shareCount,
    required this.durationStr,
    required this.qualities,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List?)
            ?.map((p) => VideoPart.fromJson(p))
            .toList() ??
        [];

    // 解析质量选项
    final List<VideoQuality> qualities = [];
    if (json['accept_quality'] != null && json['accept_description'] != null) {
      final List<int> qualityValues = List<int>.from(json['accept_quality']);
      final List<String> qualityDescriptions = List<String>.from(json['accept_description']);
      
      for (int i = 0; i < qualityValues.length; i++) {
        qualities.add(VideoQuality(
          qn: qualityValues[i],
          desc: qualityDescriptions[i],
        ));
      }
    } else {
      // 默认质量选项
      qualities.addAll([
        VideoQuality(qn: 16, desc: '流畅'),
        VideoQuality(qn: 32, desc: '清晰'),
        VideoQuality(qn: 64, desc: '高清'),
        VideoQuality(qn: 80, desc: '超清'),
        VideoQuality(qn: 112, desc: '高清 1080P'),
        VideoQuality(qn: 116, desc: '高清 1080P60'),
      ]);
    }

    return VideoInfo(
      bvid: json['bvid'] ?? '',
      aid: json['aid']?.toString() ?? '0',
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      cover: json['pic'] ?? '',
      author: json['owner']?['name'] ?? '',
      duration: json['duration'] ?? 0,
      cid: json['cid'] ?? (pages.isNotEmpty ? pages[0].cid : 0),
      parts: pages,
      description: json['desc'] ?? json['description'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      publishDate: DateTime.fromMillisecondsSinceEpoch((json['pubdate'] ?? json['publishDate'] ?? 0) * 1000),
      viewCount: json['stat']?['view'] ?? json['viewCount'] ?? 0,
      likeCount: json['stat']?['like'] ?? json['likeCount'] ?? 0,
      coinCount: json['stat']?['coin'] ?? json['coinCount'] ?? 0,
      favoriteCount: json['stat']?['favorite'] ?? json['favoriteCount'] ?? 0,
      shareCount: json['stat']?['share'] ?? json['shareCount'] ?? 0,
      durationStr: _formatDuration(json['duration'] ?? 0),
      qualities: qualities,
    );
  }
  
  static String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}

/// 视频质量选项
class VideoQuality {
  final int qn;
  final String desc;
  
  VideoQuality({required this.qn, required this.desc});
}

/// 视频分P信息
class VideoPart {
  final int cid;
  final int page;
  final String title;
  final int duration;
  final String partTitle;
  final String durationStr;

  VideoPart({
    required this.cid,
    required this.page,
    required this.title,
    required this.duration,
    required this.partTitle,
    required this.durationStr,
  });

  factory VideoPart.fromJson(Map<String, dynamic> json) {
    final String partTitle = json['part'] ?? '';
    final int duration = json['duration'] ?? 0;
    
    return VideoPart(
      cid: json['cid'] ?? 0,
      page: json['page'] ?? 1,
      title: json['title'] ?? '',
      duration: duration,
      partTitle: partTitle,
      durationStr: VideoInfo._formatDuration(duration),
    );
  }
}