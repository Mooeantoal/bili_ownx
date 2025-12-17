import 'dart:async';
import 'package:flutter/foundation.dart';
import 'download_manager.dart';
import 'metadata_service.dart';
import 'theme_service.dart';
import 'network_service.dart';
import 'play_history_service.dart';
import 'performance_service.dart';

/// 启动优化服务 - 并行初始化所有服务
class StartupService {
  static bool _initialized = false;
  static final List<Future<void> Function()> _initializers = [];
  
  /// 注册初始化任务
  static void registerInitializer(Future<void> Function() initializer) {
    if (!_initialized) {
      _initializers.add(initializer);
    }
  }
  
  /// 并行初始化所有服务
  static Future<void> initialize() async {
    if (_initialized) return;
    
    final performanceService = PerformanceService();
    performanceService.startTimer('startup_total');
    
    debugPrint('🚀 开始并行初始化服务 (${_initializers.length}个服务)...');
    
    try {
      // 并行执行所有初始化任务，同时监控每个服务的启动时间
      final futures = _initializers.asMap().entries.map((entry) {
        final index = entry.key;
        final init = entry.value;
        
        return _initializeWithMonitoring(init, 'service_$index');
      }).toList();
      
      await Future.wait(futures);
      
      _initialized = true;
      
      final totalTime = performanceService.endTimer('startup_total');
      debugPrint('✅ 所有服务初始化完成，总耗时: ${totalTime}ms');
      
      // 打印详细的启动性能报告
      performanceService.printPerformanceReport();
      
    } catch (e) {
      performanceService.endTimer('startup_total');
      debugPrint('❌ 服务初始化失败: $e');
      rethrow;
    }
  }
  
  /// 带性能监控的初始化
  static Future<void> _initializeWithMonitoring(Future<void> Function() initializer, String serviceName, [int timeoutSeconds = 10]) async {
    final performanceService = PerformanceService();
    performanceService.startTimer(serviceName);
    
    try {
      await initializer().timeout(Duration(seconds: timeoutSeconds));
      final duration = performanceService.endTimer(serviceName);
      debugPrint('✅ $serviceName 初始化成功，耗时: ${duration}ms');
    } catch (e) {
      performanceService.endTimer(serviceName);
      debugPrint('⚠️ $serviceName 初始化失败: $e');
      // 不中断整个启动流程，只记录错误
    }
  }
  
  /// 带超时的安全初始化（保留兼容性）
  static Future<void> _initializeWithTimeout(Future<void> Function() initializer, int timeoutSeconds) async {
    return _initializeWithMonitoring(initializer, 'unknown_service', timeoutSeconds);
  }
  
  /// 预热服务 - 在后台预加载常用数据
  static Future<void> warmup() async {
    if (!_initialized) {
      debugPrint('⚠️ 服务尚未初始化，跳过预热');
      return;
    }
    
    debugPrint('🔥 开始预热常用数据...');
    
    // 在隔离的future中预热，不阻塞主线程
    Future(() async {
      try {
        // 预热网络服务缓存
        await NetworkService().warmupCache();
        
        // 预热主题服务
        await ThemeService().warmup();
        
        debugPrint('🔥 预热完成');
      } catch (e) {
        debugPrint('⚠️ 预热失败: $e');
      }
    });
  }
  
  /// 获取初始化状态
  static bool get isInitialized => _initialized;
  
  /// 重置（用于测试）
  static void reset() {
    _initialized = false;
    _initializers.clear();
  }
}