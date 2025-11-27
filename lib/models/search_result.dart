/// 搜索结果视频项
class VideoSearchResult {
  final String title;         // 标题
  final String cover;         // 封面图
  final String author;        // UP主
  final int play;             // 播放量
  final String duration;      // 时长
  final String bvid;          // BV号
  final int aid;              // AV号
  
  VideoSearchResult({
    required this.title,
    required this.cover,
    required this.author,
    required this.play,
    required this.duration,
    required this.bvid,
    required this.aid,
  });
  
  /// 从 JSON 解析
  factory VideoSearchResult.fromJson(Map<String, dynamic> json) {
    return VideoSearchResult(
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      author: json['author'] ?? '',
      play: json['play'] ?? 0,
      duration: json['duration'] ?? '',
      bvid: json['bvid'] ?? '',
      aid: json['aid'] ?? 0,
    );
  }
}
