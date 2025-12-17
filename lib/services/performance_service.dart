import 'dart:async';
import 'package:flutter/foundation.dart';

/// 性能监控服务
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _metrics = {};
  
  /// 开始计时
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
    debugPrint('⏱️ 开始计时: $name');
  }
  
  /// 结束计时并记录结果
  int endTimer(String name) {
    final timer = _timers[name];
    if (timer == null) {
      debugPrint('⚠️ 计时器不存在: $name');
      return -1;
    }
    
    timer.stop();
    final duration = timer.elapsedMilliseconds;
    
    // 记录指标
    _metrics.putIfAbsent(name, () => []).add(duration);
    
    debugPrint('⏹️ 结束计时: $name = ${duration}ms');
    
    // 计算平均值
    final metrics = _metrics[name]!;
    final average = (metrics.reduce((a, b) => a + b) / metrics.length).round();
    debugPrint('📊 平均时间: $name = ${average}ms (${metrics.length}次)');
    
    timer.reset();
    return duration;
  }
  
  /// 获取平均时间
  int getAverageTime(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return 0;
    
    return (metrics.reduce((a, b) => a + b) / metrics.length).round();
  }
  
  /// 记录内存使用情况
  void recordMemoryUsage(String context) {
    // 这里可以集成内存监控
    debugPrint('💾 记录内存使用: $context');
  }
  
  /// 记录网络请求时间
  void recordNetworkTime(String url, int duration) {
    final key = 'network_${url.split('/').last}';
    _metrics.putIfAbsent(key, () => []).add(duration);
    debugPrint('🌐 网络请求: $url = ${duration}ms');
  }
  
  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final entry in _metrics.entries) {
      final metrics = entry.value;
      if (metrics.isNotEmpty) {
        final average = (metrics.reduce((a, b) => a + b) / metrics.length).round();
        final min = metrics.reduce((a, b) => a < b ? a : b);
        final max = metrics.reduce((a, b) => a > b ? a : b);
        
        report[entry.key] = {
          'average': average,
          'min': min,
          'max': max,
          'count': metrics.length,
        };
      }
    }
    
    return report;
  }
  
  /// 打印性能报告
  void printPerformanceReport() {
    final report = getPerformanceReport();
    
    debugPrint('\n📈 性能报告:');
    debugPrint('=' * 50);
    
    for (final entry in report.entries) {
      final data = entry.value as Map<String, dynamic>;
      debugPrint('${entry.key}:');
      debugPrint('  平均: ${data['average']}ms');
      debugPrint('  最小: ${data['min']}ms');
      debugPrint('  最大: ${data['max']}ms');
      debugPrint('  次数: ${data['count']}');
      debugPrint('');
    }
  }
  
  /// 重置所有指标
  void reset() {
    _timers.clear();
    _metrics.clear();
    debugPrint('🔄 性能指标已重置');
  }
}