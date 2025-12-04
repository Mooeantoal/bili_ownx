import 'package:flutter/foundation.dart';
import '../models/danmaku.dart';
import '../api/danmaku_api.dart';

/// 弹幕服务
class DanmakuService extends ChangeNotifier {
  List<Danmaku> _danmakus = [];
  List<Danmaku> _filteredDanmakus = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // 弹幕设置
  bool _showScroll = true;
  bool _showTop = true;
  bool _showBottom = true;
  double _opacity = 1.0;
  double _fontSize = 16.0;
  int _maxCount = 100;
  
  // 弹幕过滤
  String _filterKeyword = '';
  bool _filterTopLevel = false;
  bool _filterColorful = false;

  List<Danmaku> get danmakus => _filteredDanmakus;
  List<Danmaku> get allDanmakus => _danmakus;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // 设置相关
  bool get showScroll => _showScroll;
  bool get showTop => _showTop;
  bool get showBottom => _showBottom;
  double get opacity => _opacity;
  double get fontSize => _fontSize;
  int get maxCount => _maxCount;

  /// 加载弹幕列表
  Future<void> loadDanmakus({
    required String bvid,
    required int cid,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final danmakus = await DanmakuApi.getDanmakuList(
        bvid: bvid,
        cid: cid,
      );

      _danmakus = danmakus;
      _applyFilters();
      
      debugPrint('成功加载 ${danmakus.length} 条弹幕');
    } catch (e) {
      _errorMessage = '加载弹幕失败: $e';
      debugPrint('加载弹幕失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 发送弹幕
  Future<bool> sendDanmaku({
    required String bvid,
    required int cid,
    required Danmaku danmaku,
  }) async {
    try {
      final success = await DanmakuApi.sendDanmaku(
        bvid: bvid,
        cid: cid,
        danmaku: danmaku,
      );

      if (success) {
        // 添加到本地弹幕列表
        _danmakus.add(danmaku);
        _applyFilters();
        notifyListeners();
        
        debugPrint('弹幕发送成功: ${danmaku.text}');
      }

      return success;
    } catch (e) {
      _errorMessage = '发送弹幕失败: $e';
      debugPrint('发送弹幕失败: $e');
      return false;
    }
  }

  /// 添加本地弹幕（用于测试或离线模式）
  void addLocalDanmaku(Danmaku danmaku) {
    _danmakus.add(danmaku);
    _applyFilters();
    notifyListeners();
  }

  /// 清空弹幕
  void clearDanmakus() {
    _danmakus.clear();
    _filteredDanmakus.clear();
    notifyListeners();
  }

  /// 设置弹幕显示状态
  void setScrollVisibility(bool visible) {
    _showScroll = visible;
    _applyFilters();
    notifyListeners();
  }

  void setTopVisibility(bool visible) {
    _showTop = visible;
    _applyFilters();
    notifyListeners();
  }

  void setBottomVisibility(bool visible) {
    _showBottom = visible;
    _applyFilters();
    notifyListeners();
  }

  /// 设置透明度
  void setOpacity(double opacity) {
    _opacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 设置字体大小
  void setFontSize(double fontSize) {
    _fontSize = fontSize.clamp(12.0, 24.0);
    notifyListeners();
  }

  /// 设置最大弹幕数量
  void setMaxCount(int count) {
    _maxCount = count.clamp(10, 200);
    _applyFilters();
    notifyListeners();
  }

  /// 设置过滤关键词
  void setFilterKeyword(String keyword) {
    _filterKeyword = keyword;
    _applyFilters();
    notifyListeners();
  }

  /// 设置是否过滤高级弹幕
  void setFilterTopLevel(bool filter) {
    _filterTopLevel = filter;
    _applyFilters();
    notifyListeners();
  }

  /// 设置是否过滤彩色弹幕
  void setFilterColorful(bool filter) {
    _filterColorful = filter;
    _applyFilters();
    notifyListeners();
  }

  /// 应用所有过滤条件
  void _applyFilters() {
    _filteredDanmakus = _danmakus.where((danmaku) {
      // 按类型过滤
      switch (danmaku.type) {
        case DanmakuType.scroll:
          if (!_showScroll) return false;
          break;
        case DanmakuType.top:
          if (!_showTop) return false;
          break;
        case DanmakuType.bottom:
          if (!_showBottom) return false;
          break;
      }

      // 按关键词过滤
      if (_filterKeyword.isNotEmpty && 
          !danmaku.text.toLowerCase().contains(_filterKeyword.toLowerCase())) {
        return false;
      }

      // 按颜色过滤（非白色视为彩色）
      if (_filterColorful && danmaku.color.value != Colors.white.value) {
        return false;
      }

      return true;
    }).take(_maxCount).toList();

    // 按时间排序
    _filteredDanmakus.sort((a, b) => a.time.compareTo(b.time));
  }

  /// 重置所有设置为默认值
  void resetToDefaults() {
    _showScroll = true;
    _showTop = true;
    _showBottom = true;
    _opacity = 1.0;
    _fontSize = 16.0;
    _maxCount = 100;
    _filterKeyword = '';
    _filterTopLevel = false;
    _filterColorful = false;
    
    _applyFilters();
    notifyListeners();
  }

  /// 获取弹幕统计信息
  Map<String, dynamic> getStatistics() {
    final scrollCount = _danmakus.where((d) => d.type == DanmakuType.scroll).length;
    final topCount = _danmakus.where((d) => d.type == DanmakuType.top).length;
    final bottomCount = _danmakus.where((d) => d.type == DanmakuType.bottom).length;
    
    final colorCounts = <Color, int>{};
    for (final danmaku in _danmakus) {
      colorCounts[danmaku.color] = (colorCounts[danmaku.color] ?? 0) + 1;
    }

    return {
      'totalCount': _danmakus.length,
      'scrollCount': scrollCount,
      'topCount': topCount,
      'bottomCount': bottomCount,
      'colorCounts': colorCounts,
      'averageLength': _danmakus.isEmpty 
          ? 0.0 
          : _danmakus.map((d) => d.text.length).reduce((a, b) => a + b) / _danmakus.length,
    };
  }

  /// 导出弹幕为JSON
  String exportToJson() {
    final data = {
      'danmakus': _danmakus.map((d) => d.toJson()).toList(),
      'settings': {
        'showScroll': _showScroll,
        'showTop': _showTop,
        'showBottom': _showBottom,
        'opacity': _opacity,
        'fontSize': _fontSize,
        'maxCount': _maxCount,
      },
      'exportTime': DateTime.now().toIso8601String(),
    };
    
    return data.toString();
  }

  /// 从JSON导入弹幕
  bool importFromJson(String json) {
    try {
      // 这里应该解析JSON并恢复弹幕数据
      // 简化实现，实际项目中应该使用dart:convert
      debugPrint('弹幕导入功能待实现');
      return false;
    } catch (e) {
      debugPrint('弹幕导入失败: $e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}