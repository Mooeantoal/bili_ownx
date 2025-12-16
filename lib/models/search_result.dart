/// 搜索结果视频项
class VideoSearchResult {
  final String title;         // 标题
  final String cover;         // 封面图
  final String author;        // UP主
  final int play;             // 播放量
  final String duration;      // 时长
  final String bvid;          // BV号
  final String aid;           // AV号 (改为字符串类型以支持大数值)
  
  // 新增字段
  final int danmaku;          // 弹幕数
  final int like;             // 点赞数
  final int coin;             // 投币数
  final int favorite;         // 收藏数
  final int reply;            // 评论数
  final int pubdate;          // 发布时间戳
  final String description;   // 视频简介
  final String mid;           // UP主ID
  
  VideoSearchResult({
    required this.title,
    required this.cover,
    required this.author,
    required this.play,
    required this.duration,
    required this.bvid,
    required this.aid,
    this.danmaku = 0,
    this.like = 0,
    this.coin = 0,
    this.favorite = 0,
    this.reply = 0,
    this.pubdate = 0,
    this.description = '',
    this.mid = '',
  });
  
  /// 检查是否有有效的视频ID
  bool get hasValidId => bvid.isNotEmpty || aid != 0;
  
  /// 从 JSON 解析
  factory VideoSearchResult.fromJson(Map<String, dynamic> json) {
    try {
      // 调试：打印原始数据
      print('=== 解析视频项 ===');
      print('原始数据: $json');
      print('所有字段: ${json.keys.toList()}');
      
      // 尝试多种可能的字段名
      String title = '';
      String cover = '';
      String author = '';
      int play = 0;
      String duration = '';
      String bvid = '';
      String aid = ''; // 改为字符串类型
    
    // 处理嵌套结构（B站 API 常见结构）
    Map<String, dynamic> videoData = json;
    
    // 如果有嵌套的 video 或 archive 字段
    if (json.containsKey('video') && json['video'] is Map) {
      videoData = {...videoData, ...json['video']};
    } else if (json.containsKey('archive') && json['archive'] is Map) {
      videoData = {...videoData, ...json['archive']};
    }
    
    // 提取基本信息 - 添加类型安全检查
    title = _parseString(videoData['title'] ?? json['title'] ?? json['name'] ?? '');
    cover = _parseString(videoData['cover'] ?? videoData['pic'] ?? json['cover'] ?? json['pic'] ?? json['image'] ?? '');
    author = _parseString(videoData['author'] ?? videoData['uname'] ?? videoData['owner'] ?? json['author'] ?? json['uname'] ?? json['owner'] ?? '');
    play = _parsePlayCount(videoData['play'] ?? videoData['video_view'] ?? json['play'] ?? json['video_view'] ?? 0);
    duration = _parseDuration(videoData['duration'] ?? videoData['length'] ?? json['duration'] ?? json['length'] ?? '');
    bvid = _parseString(videoData['bvid'] ?? videoData['bvid_id'] ?? json['bvid'] ?? json['bvid_id'] ?? '');
    aid = _parseString((videoData['aid'] ?? videoData['id'] ?? json['aid'] ?? json['id'] ?? 0).toString());
    
    // 如果还是没有 bvid，尝试从其他字段构造
    if (bvid.isEmpty) {
      // 尝试从 uri 或 link 字段提取
      final uri = videoData['uri'] ?? json['uri'] ?? '';
      final link = videoData['link'] ?? json['link'] ?? '';
      
      for (final text in [uri, link]) {
        if (text is String && text.contains('BV')) {
          final match = RegExp(r'BV[a-zA-Z0-9]+').firstMatch(text);
          if (match != null) {
            bvid = match.group(0) ?? '';
            break;
          }
        }
      }
      
      // 如果仍然没有 bvid，但有 param 和 goto="av"，使用 AV 号
      if (bvid.isEmpty) {
        final param = videoData['param'] ?? json['param'];
        final goto = videoData['goto'] ?? json['goto'];
        
        if (param != null && goto == 'av') {
          // 使用 AV 号，将 aid 设置为 param 的值
          aid = _parseString(param.toString());
          print('从 param 字段提取 AV 号: $aid');
        }
      }
    }
    
    print('解析结果:');
    print('- title: $title');
    print('- bvid: $bvid');
    print('- aid: $aid');
    print('- author: $author');
    print('- play: $play');
    print('---');
    
    // 解析新增字段
    final danmaku = _parseCount(videoData['danmaku'] ?? videoData['video_danmaku'] ?? json['danmaku'] ?? json['video_danmaku'] ?? 0);
    final like = _parseCount(videoData['like'] ?? videoData['video_like'] ?? json['like'] ?? json['video_like'] ?? 0);
    final coin = _parseCount(videoData['coin'] ?? videoData['video_coin'] ?? json['coin'] ?? json['video_coin'] ?? 0);
    final favorite = _parseCount(videoData['favorite'] ?? videoData['video_fav'] ?? json['favorite'] ?? json['video_fav'] ?? 0);
    final reply = _parseCount(videoData['reply'] ?? videoData['video_reply'] ?? json['reply'] ?? json['video_reply'] ?? 0);
    final pubdate = _parseTimestamp(videoData['pubdate'] ?? videoData['created'] ?? json['pubdate'] ?? json['created'] ?? 0);
    final description = _parseString(videoData['description'] ?? videoData['desc'] ?? json['description'] ?? json['desc'] ?? '');
    final mid = _parseString(videoData['mid'] ?? videoData['uid'] ?? json['mid'] ?? json['uid'] ?? '');

    return VideoSearchResult(
      title: title,
      cover: cover,
      author: author,
      play: play,
      duration: duration,
      bvid: bvid,
      aid: aid,
      danmaku: danmaku,
      like: like,
      coin: coin,
      favorite: favorite,
      reply: reply,
      pubdate: pubdate,
      description: description,
      mid: mid,
    );
    } catch (e, stackTrace) {
      print('❌ 解析视频项出错: $e');
      print('堆栈跟踪: $stackTrace');
      print('原始数据: $json');
      
      // 返回一个安全的默认对象
      return VideoSearchResult(
        title: _parseString(json['title'] ?? json['name'] ?? '解析失败'),
        cover: _parseString(json['cover'] ?? json['pic'] ?? ''),
        author: _parseString(json['author'] ?? json['uname'] ?? '未知UP主'),
        play: _parsePlayCount(json['play'] ?? 0),
        duration: _parseString(json['duration'] ?? ''),
        bvid: _parseString(json['bvid'] ?? ''),
        aid: _parseString((json['aid'] ?? 0).toString()),
        description: '数据解析出错: $e',
      );
    }
  }
  
  /// 安全解析字符串
  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  /// 安全解析整数
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  /// 解析数字统计（播放量、点赞数等）
  static int _parseCount(dynamic count) {
    return _parsePlayCount(count);
  }

  /// 解析时长（支持秒数或字符串格式）
  static String _parseDuration(dynamic duration) {
    if (duration == null) return '';
    
    // 如果是字符串，直接返回
    if (duration is String) return duration.trim();
    
    // 如果是数字（秒数），转换为 分:秒 格式
    if (duration is int) {
      if (duration <= 0) return '';
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    
    // 其他情况，尝试转换为字符串
    return duration.toString().trim();
  }

  /// 解析时间戳
  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) return timestamp;
    if (timestamp is String) return int.tryParse(timestamp) ?? 0;
    return 0;
  }
}
