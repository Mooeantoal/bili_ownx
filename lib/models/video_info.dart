/// 视频信息模型
class VideoInfo {
  final String bvid;
  final int aid;
  final String title;
  final String desc;
  final String cover;
  final String author;
  final int duration;
  final int cid; // 默认第一P的cid
  final List<VideoPart> parts; // 分P列表

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
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List?)
            ?.map((p) => VideoPart.fromJson(p))
            .toList() ??
        [];

    return VideoInfo(
      bvid: json['bvid'] ?? '',
      aid: json['aid'] ?? 0,
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      cover: json['pic'] ?? '',
      author: json['owner']?['name'] ?? '',
      duration: json['duration'] ?? 0,
      cid: json['cid'] ?? (pages.isNotEmpty ? pages[0].cid : 0),
      parts: pages,
    );
  }
}

/// 视频分P信息
class VideoPart {
  final int cid;
  final int page;
  final String title;
  final int duration;

  VideoPart({
    required this.cid,
    required this.page,
    required this.title,
    required this.duration,
  });

  factory VideoPart.fromJson(Map<String, dynamic> json) {
    return VideoPart(
      cid: json['cid'] ?? 0,
      page: json['page'] ?? 1,
      title: json['part'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}
