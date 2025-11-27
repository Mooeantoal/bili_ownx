import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史管理服务
class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 20;

  /// 获取搜索历史
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// 添加搜索记录
  static Future<void> addHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    // 移除重复项
    history.remove(keyword);
    
    // 添加到开头
    history.insert(0, keyword);

    // 限制历史记录数量
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }

    await prefs.setStringList(_key, history);
  }

  /// 删除单条历史记录
  static Future<void> removeHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    history.remove(keyword);
    await prefs.setStringList(_key, history);
  }

  /// 清空历史记录
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
