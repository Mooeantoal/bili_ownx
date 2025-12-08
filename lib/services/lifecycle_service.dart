import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pip_service.dart';

/// 应用生命周期服务
/// 用于监听应用状态变化，自动处理画中画等行为
class LifecycleService extends WidgetsBindingObserver {
  static final LifecycleService _instance = LifecycleService._internal();
  factory LifecycleService() => _instance;
  LifecycleService._internal();

  final PiPService _pipService = PiPService();
  bool _isVideoPlaying = false;
  VoidCallback? _onAppPaused;

  /// 是否正在播放视频
  bool get isVideoPlaying => _isVideoPlaying;

  /// 设置视频播放状态
  void setVideoPlaying(bool isPlaying) {
    _isVideoPlaying = isPlaying;
  }

  /// 设置应用暂停回调
  void setOnAppPaused(VoidCallback callback) {
    _onAppPaused = callback;
  }

  /// 初始化生命周期监听
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        // 应用失去焦点但仍然可见
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏（较新的Flutter版本）
        _handleAppHidden();
        break;
    }
  }

  /// 处理应用暂停
  void _handleAppPaused() async {
    // 如果正在播放视频且不在画中画模式，尝试自动进入画中画
    if (_isVideoPlaying && !_pipService.isInPiPMode) {
      try {
        await _pipService.enterPiPMode();
      } catch (e) {
        print('自动进入画中画失败: $e');
      }
    }
    
    _onAppPaused?.call();
  }

  /// 处理应用恢复
  void _handleAppResumed() {
    // 如果在画中画模式且不需要保持，可以自动退出
    if (_pipService.isInPiPMode) {
      // 这里可以根据业务需求决定是否自动退出画中画
      // 一般情况下，用户点击回到应用时应该退出画中画
      // _pipService.exitPiPMode();
    }
  }

  /// 处理应用隐藏
  void _handleAppHidden() {
    _handleAppPaused();
  }

  /// 处理应用分离
  void _handleAppDetached() {
    // 清理资源
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 释放资源
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// 应用生命周期管理器
/// 用于更方便地管理应用生命周期相关的功能
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  final bool enableAutoPiP;
  final VoidCallback? onAppPaused;
  final VoidCallback? onAppResumed;

  const AppLifecycleManager({
    super.key,
    required this.child,
    this.enableAutoPiP = true,
    this.onAppPaused,
    this.onAppResumed,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  final LifecycleService _lifecycleService = LifecycleService();

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoPiP) {
      _lifecycleService.initialize();
      _lifecycleService.setOnAppPaused(widget.onAppPaused);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        widget.onAppPaused?.call();
        break;
      case AppLifecycleState.resumed:
        widget.onAppResumed?.call();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}