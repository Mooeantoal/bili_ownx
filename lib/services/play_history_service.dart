import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 播放历史记录项
class PlayHistoryItem {
  final String bvid;
  final String title;
  final String cover;
  final int position; // 播放位置（秒）
  final int duration; // 视频总时长（秒）
  final DateTime timestamp; // 观看时间

  PlayHistoryItem({
    required this.bvid,
    required this.title,
    required this.cover,
    required this.position,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'title': title,
        'cover': cover,
        'position': position,
        'duration': duration,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PlayHistoryItem.fromJson(Map<String, dynamic> json) {
    return PlayHistoryItem(
      bvid: json['bvid'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      position: json['position'] ?? 0,
      duration: json['duration'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// 播放历史管理服务
class PlayHistoryService {
  static const String _key = 'play_history';
  static const int _maxHistory = 50;

  /// 获取播放历史
  static Future<List<PlayHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_key);
    
    if (historyJson == null) return [];

    final List<dynamic> historyList = jsonDecode(historyJson);
    return historyList
        .map((item) => PlayHistoryItem.fromJson(item))
        .toList();
  }

  /// 添加或更新播放历史
  static Future<void> addHistory({
    required String bvid,
    required String title,
    required String cover,
    required int position,
    required int duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<PlayHistoryItem> history = await getHistory();

    // 移除相同 bvid 的旧记录
    history.removeWhere((item) => item.bvid == bvid);

    // 添加新记录到开头
    history.insert(
      0,
      PlayHistoryItem(
        bvid: bvid,
        title: title,
        cover: cover,
        position: position,
        duration: duration,
        timestamp: DateTime.now(),
      ),
    );

    // 限制历史记录数量
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }

    // 保存
    final historyJson = jsonEncode(
      history.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_key, historyJson);
  }

  /// 获取单个视频的观看进度
  static Future<int?> getPosition(String bvid) async {
    final history = await getHistory();
    final item = history.firstWhere(
      (item) => item.bvid == bvid,
      orElse: () => PlayHistoryItem(
        bvid: '',
        title: '',
        cover: '',
        position: 0,
        duration: 0,
        timestamp: DateTime.now(),
      ),
    );

    return item.bvid.isNotEmpty ? item.position : null;
  }

  /// 清空历史记录
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
