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
    // 调试：打印原始数据
    print('=== 解析视频项 ===');
    print('原始数据: $json');
    print('所有字段: ${json.keys.toList()}');
    
    // 尝试多种可能的字段名
    final title = json['title'] ?? json['name'] ?? '';
    final cover = json['cover'] ?? json['pic'] ?? json['image'] ?? '';
    final author = json['author'] ?? json['uname'] ?? json['owner'] ?? '';
    final play = _parsePlayCount(json['play'] ?? json['video_view'] ?? 0);
    final duration = json['duration'] ?? json['length'] ?? '';
    final bvid = json['bvid'] ?? json['bvid_id'] ?? '';
    final aid = json['aid'] ?? json['id'] ?? 0;
    
    print('解析结果:');
    print('- title: $title');
    print('- bvid: $bvid');
    print('- aid: $aid');
    print('- author: $author');
    print('---');
    
    return VideoSearchResult(
      title: title,
      cover: cover,
      author: author,
      play: play,
      duration: duration,
      bvid: bvid,
      aid: aid,
    );
  }
  
  /// 解析播放量（处理字符串格式的播放量）
  static int _parsePlayCount(dynamic play) {
    if (play is int) return play;
    if (play is String) {
      // 移除"万"等单位并转换
      final cleanStr = play.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleanStr) ?? 0;
    }
    return 0;
  }
}
