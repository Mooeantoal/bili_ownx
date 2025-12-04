import 'package:flutter/material.dart';
import '../models/danmaku.dart';
import 'dart:async';

/// 弹幕画布组件
class DanmakuCanvas extends StatefulWidget {
  final List<Danmaku> danmakus;
  final bool isPlaying;
  final double opacity;
  final double fontSize;
  final bool showScroll;
  final bool showTop;
  final bool showBottom;
  final Function(Danmaku)? onDanmakuTap;

  const DanmakuCanvas({
    super.key,
    this.danmakus = const [],
    this.isPlaying = true,
    this.opacity = 1.0,
    this.fontSize = 16.0,
    this.showScroll = true,
    this.showTop = true,
    this.showBottom = true,
    this.onDanmakuTap,
  });

  @override
  State<DanmakuCanvas> createState() => _DanmakuCanvasState();
}

class _DanmakuCanvasState extends State<DanmakuCanvas> {
  final List<Danmaku> _activeDanmakus = [];
  final List<DanmakuTrack> _tracks = [];
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeTracks();
    _startDanmakuFlow();
  }

  @override
  void didUpdateWidget(DanmakuCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.danmakus != widget.danmakus) {
      _currentIndex = 0;
      _clearActiveDanmakus();
    }
    
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startDanmakuFlow();
      } else {
        _pauseDanmakuFlow();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeTracks() {
    _tracks.clear();
    // 创建弹幕轨道，通常屏幕可以显示5-6行弹幕
    for (int i = 0; i < 6; i++) {
      _tracks.add(DanmakuTrack(
        top: i * 40.0 + 20.0,
        height: 30.0,
      ));
    }
  }

  void _startDanmakuFlow() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!widget.isPlaying || widget.danmakus.isEmpty) return;
      
      _addNextDanmaku();
    });
  }

  void _pauseDanmakuFlow() {
    _timer?.cancel();
  }

  void _addNextDanmaku() {
    if (_currentIndex >= widget.danmakus.length) {
      _currentIndex = 0; // 循环播放
    }

    final danmaku = widget.danmakus[_currentIndex];
    
    // 检查是否应该显示该类型的弹幕
    bool shouldShow = false;
    switch (danmaku.type) {
      case DanmakuType.scroll:
        shouldShow = widget.showScroll;
        break;
      case DanmakuType.top:
        shouldShow = widget.showTop;
        break;
      case DanmakuType.bottom:
        shouldShow = widget.showBottom;
        break;
    }

    if (shouldShow) {
      setState(() {
        _activeDanmakus.add(danmaku);
      });
    }

    _currentIndex++;
  }

  void _clearActiveDanmakus() {
    setState(() {
      _activeDanmakus.clear();
    });
  }

  void _onDanmakuComplete(Danmaku danmaku) {
    setState(() {
      _activeDanmakus.remove(danmaku);
    });
  }

  DanmakuTrack? _findAvailableTrack() {
    for (final track in _tracks) {
      if (!track.isOccupied) {
        return track;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: widget.opacity,
          child: Stack(
            children: [
              // 滚动弹幕
              if (widget.showScroll)
                ..._activeDanmakus
                    .where((d) => d.type == DanmakuType.scroll)
                    .map((danmaku) {
                  final track = _findAvailableTrack();
                  if (track == null) return const SizedBox.shrink();
                  
                  return Positioned(
                    top: track.top,
                    left: 0,
                    right: 0,
                    child: DanmakuWidget(
                      danmaku: danmaku.copyWith(fontSize: widget.fontSize),
                      screenWidth: MediaQuery.of(context).size.width,
                      onComplete: () => _onDanmakuComplete(danmaku),
                    ),
                  );
                }),
              
              // 顶部弹幕
              if (widget.showTop)
                ..._activeDanmakus
                    .where((d) => d.type == DanmakuType.top)
                    .mapIndexed((index, danmaku) {
                  return Positioned(
                    top: 20.0 + (index % 3) * 40.0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => widget.onDanmakuTap?.call(danmaku),
                        child: DanmakuWidget(
                          danmaku: danmaku.copyWith(fontSize: widget.fontSize),
                          screenWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  );
                }),
              
              // 底部弹幕
              if (widget.showBottom)
                ..._activeDanmakus
                    .where((d) => d.type == DanmakuType.bottom)
                    .mapIndexed((index, danmaku) {
                  return Positioned(
                    bottom: 20.0 + (index % 2) * 40.0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => widget.onDanmakuTap?.call(danmaku),
                        child: DanmakuWidget(
                          danmaku: danmaku.copyWith(fontSize: widget.fontSize),
                          screenWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 扩展方法，为List添加mapIndexed
extension ListExtension<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}

/// 扩展方法，为Danmaku添加copyWith
extension DanmakuExtension on Danmaku {
  Danmaku copyWith({
    String? text,
    Color? color,
    double? fontSize,
    DanmakuType? type,
    DateTime? time,
    String? senderId,
    String? senderName,
  }) {
    return Danmaku(
      text: text ?? this.text,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      type: type ?? this.type,
      time: time ?? this.time,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
    );
  }
}