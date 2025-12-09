/// BiliYou风格视频信息模型
class BiliVideoInfo {
  final String bvid;
  final String aid;
  final String title;
  final String author;
  final String cover;
  final String duration;
  final int play;
  final int danmaku;
  final int pubdate;
  final int cid;

  const BiliVideoInfo({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.play,
    required this.danmaku,
    required this.pubdate,
    required this.cid,
  });

  factory BiliVideoInfo.fromJson(Map<String, dynamic> json) {
    return BiliVideoInfo(
      bvid: json['bvid']?.toString() ?? '',
      aid: json['aid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? json['up']?.toString() ?? '',
      cover: json['pic']?.toString() ?? json['cover']?.toString() ?? '',
      duration: json['duration']?.toString() ?? json['length']?.toString() ?? '',
      play: _parseInt(json['play'] ?? json['stat']?['play']),
      danmaku: _parseInt(json['danmaku'] ?? json['video_review']),
      pubdate: _parseInt(json['pubdate'] ?? json['created']),
      cid: _parseInt(json['cid'] ?? 0),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  bool get isValid => bvid.isNotEmpty || aid.isNotEmpty;
}