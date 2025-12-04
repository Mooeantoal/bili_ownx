import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// 弹幕模型
class Danmaku {
  final String text;
  final Color color;
  final double fontSize;
  final DanmakuType type;
  final DateTime time;
  final String? senderId;
  final String? senderName;

  const Danmaku({
    required this.text,
    this.color = Colors.white,
    this.fontSize = 16.0,
    this.type = DanmakuType.scroll,
    required this.time,
    this.senderId,
    this.senderName,
  });

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    return Danmaku(
      text: json['text'] ?? '',
      color: Color(json['color'] ?? 0xFFFFFFFF),
      fontSize: (json['fontSize'] ?? 16.0).toDouble(),
      type: DanmakuType.values[json['type'] ?? 0],
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      senderId: json['senderId'],
      senderName: json['senderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'color': color.value,
      'fontSize': fontSize,
      'type': type.index,
      'time': time.millisecondsSinceEpoch,
      'senderId': senderId,
      'senderName': senderName,
    };
  }

  /// 创建滚动弹幕
  factory Danmaku.scroll(String text, {Color? color, double? fontSize}) {
    return Danmaku(
      text: text,
      color: color ?? Colors.white,
      fontSize: fontSize ?? 16.0,
      type: DanmakuType.scroll,
      time: DateTime.now(),
    );
  }

  /// 创建顶部弹幕
  factory Danmaku.top(String text, {Color? color, double? fontSize}) {
    return Danmaku(
      text: text,
      color: color ?? Colors.white,
      fontSize: fontSize ?? 16.0,
      type: DanmakuType.top,
      time: DateTime.now(),
    );
  }

  /// 创建底部弹幕
  factory Danmaku.bottom(String text, {Color? color, double? fontSize}) {
    return Danmaku(
      text: text,
      color: color ?? Colors.white,
      fontSize: fontSize ?? 16.0,
      type: DanmakuType.bottom,
      time: DateTime.now(),
    );
  }
}

/// 弹幕类型
enum DanmakuType {
  scroll,  // 滚动弹幕
  top,     // 顶部弹幕
  bottom,  // 底部弹幕
}

/// 弹幕显示状态
enum DanmakuDisplayState {
  show,    // 显示
  hide,    // 隐藏
  pause,   // 暂停
}

/// 弹幕轨道
class DanmakuTrack {
  final double top;
  final double height;
  bool isOccupied;

  DanmakuTrack({
    required this.top,
    required this.height,
    this.isOccupied = false,
  });
}

/// 单个弹幕Widget
class DanmakuWidget extends StatefulWidget {
  final Danmaku danmaku;
  final double screenWidth;
  final VoidCallback? onComplete;

  const DanmakuWidget({
    super.key,
    required this.danmaku,
    required this.screenWidth,
    this.onComplete,
  });

  @override
  State<DanmakuWidget> createState() => _DanmakuWidgetState();
}

class _DanmakuWidgetState extends State<DanmakuWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    
    // 计算动画时长（基于屏幕宽度和文字长度）
    final textWidth = _calculateTextWidth();
    final duration = Duration(
      milliseconds: (widget.screenWidth + textWidth) * 8,
    );

    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0), // 从右侧开始
      end: Offset(-1.0, 0.0),  // 到左侧结束
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.danmaku.text,
        style: TextStyle(
          color: widget.danmaku.color,
          fontSize: widget.danmaku.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.danmaku.type) {
      case DanmakuType.scroll:
        return AnimatedBuilder(
          animation: _offsetAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _offsetAnimation,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.danmaku.text,
              style: TextStyle(
                color: widget.danmaku.color,
                fontSize: widget.danmaku.fontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      
      case DanmakuType.top:
      case DanmakuType.bottom:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.danmaku.text,
            style: TextStyle(
              color: widget.danmaku.color,
              fontSize: widget.danmaku.fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
    }
  }
}