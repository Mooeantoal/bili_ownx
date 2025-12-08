import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pip/flutter_pip.dart';
import 'package:super_easy_permissions/super_easy_permissions.dart';

/// 画中画服务
class PiPService {
  static final PiPService _instance = PiPService._internal();
  factory PiPService() => _instance;
  PiPService._internal();

  bool _isInPiPMode = false;
  bool _isPiPAvailable = false;
  StreamSubscription<bool>? _pipModeSubscription;

  /// 是否在画中画模式
  bool get isInPiPMode => _isInPiPMode;

  /// 画中画是否可用
  bool get isPiPAvailable => _isPiPAvailable;

  /// 初始化画中画服务
  Future<void> initialize() async {
    // 检查画中画权限
    _isPiPAvailable = await _checkPiPPermission();
    
    // 监听画中画模式变化
    _pipModeSubscription = FlutterPiP.pipModeStream.listen((isInPiP) {
      _isInPiPMode = isInPiP;
    });
  }

  /// 检查画中画权限
  Future<bool> _checkPiPPermission() async {
    try {
      // 检查是否有画中画权限
      if (await SuperEasyPermissions.isGranted(Permission.pictureInPicture)) {
        return true;
      }
      
      // 尝试请求画中画权限
      final result = await SuperEasyPermissions.requestPermission(
        Permission.pictureInPicture,
      );
      return result;
    } catch (e) {
      print('检查画中画权限失败: $e');
      return false;
    }
  }

  /// 进入画中画模式
  Future<bool> enterPiPMode({
    double aspectRatio = 16.0 / 9.0,
    String title = 'Bilimiao',
  }) async {
    try {
      if (!_isPiPAvailable) {
        throw Exception('画中画功能不可用');
      }

      final pipConfig = PiPConfig(
        aspectRatio: aspectRatio,
        sourceRectHint: Rect.zero,
        title: title,
      );

      final success = await FlutterPiP.enterPiPMode(pipConfig);
      if (success) {
        _isInPiPMode = true;
      }
      return success;
    } catch (e) {
      print('进入画中画模式失败: $e');
      return false;
    }
  }

  /// 退出画中画模式
  Future<bool> exitPiPMode() async {
    try {
      final success = await FlutterPiP.exitPiPMode();
      if (success) {
        _isInPiPMode = false;
      }
      return success;
    } catch (e) {
      print('退出画中画模式失败: $e');
      return false;
    }
  }

  /// 画中画模式开关
  Future<bool> togglePiPMode({
    double aspectRatio = 16.0 / 9.0,
    String title = 'Bilimiao',
  }) async {
    if (_isInPiPMode) {
      return await exitPiPMode();
    } else {
      return await enterPiPMode(aspectRatio: aspectRatio, title: title);
    }
  }

  /// 设置画中画配置
  Future<bool> updatePiPConfig({
    double? aspectRatio,
    String? title,
  }) async {
    try {
      if (!_isInPiPMode) return false;

      final pipConfig = PiPConfig(
        aspectRatio: aspectRatio ?? 16.0 / 9.0,
        sourceRectHint: Rect.zero,
        title: title ?? 'Bilimiao',
      );

      return await FlutterPiP.updatePiPConfig(pipConfig);
    } catch (e) {
      print('更新画中画配置失败: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _pipModeSubscription?.cancel();
    _pipModeSubscription = null;
  }
}

/// 画中画配置
class PiPConfig {
  final double aspectRatio;
  final Rect sourceRectHint;
  final String title;

  const PiPConfig({
    required this.aspectRatio,
    required this.sourceRectHint,
    required this.title,
  });
}

/// 画中画状态监听器
mixin PiPStateMixin<T extends StatefulWidget> on State<T> {
  final PiPService _pipService = PiPService();
  
  /// 是否在画中画模式
  bool get isInPiPMode => _pipService.isInPiPMode;

  /// 画中画是否可用
  bool get isPiPAvailable => _pipService.isPiPAvailable;

  @override
  void initState() {
    super.initState();
    _pipService.initialize();
  }

  @override
  void dispose() {
    _pipService.dispose();
    super.dispose();
  }

  /// 进入画中画模式
  Future<bool> enterPiPMode({
    double aspectRatio = 16.0 / 9.0,
    String? title,
  }) async {
    return await _pipService.enterPiPMode(
      aspectRatio: aspectRatio,
      title: title ?? widget.toString(),
    );
  }

  /// 退出画中画模式
  Future<bool> exitPiPMode() async {
    return await _pipService.exitPiPMode();
  }

  /// 切换画中画模式
  Future<bool> togglePiPMode({
    double aspectRatio = 16.0 / 9.0,
    String? title,
  }) async {
    return await _pipService.togglePiPMode(
      aspectRatio: aspectRatio,
      title: title ?? widget.toString(),
    );
  }

  /// 画中画模式变化回调
  void onPiPModeChanged(bool isInPiP) {
    if (mounted) {
      setState(() {
        // 更新UI状态
      });
    }
  }
}