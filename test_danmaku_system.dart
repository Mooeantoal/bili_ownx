import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/danmaku.dart';
import '../lib/services/danmaku_service.dart';
import '../lib/widgets/danmaku_canvas.dart';
import '../lib/widgets/danmaku_input.dart';
import '../lib/widgets/danmaku_settings.dart';

void main() {
  group('弹幕系统测试', () {
    late DanmakuService danmakuService;

    setUp(() {
      danmakuService = DanmakuService();
    });

    test('弹幕模型创建测试', () {
      final danmaku = Danmaku.scroll(
        '测试弹幕',
        color: Colors.red,
        fontSize: 18.0,
      );

      expect(danmaku.text, '测试弹幕');
      expect(danmaku.color, Colors.red);
      expect(danmaku.fontSize, 18.0);
      expect(danmaku.type, DanmakuType.scroll);
    });

    test('弹幕服务添加弹幕测试', () {
      final danmaku = Danmaku.top('顶部弹幕');
      danmakuService.addLocalDanmaku(danmaku);

      expect(danmakuService.danmakus.length, 1);
      expect(danmakuService.danmakus.first.text, '顶部弹幕');
      expect(danmakuService.danmakus.first.type, DanmakuType.top);
    });

    test('弹幕过滤测试', () {
      // 添加不同类型的弹幕
      danmakuService.addLocalDanmaku(Danmaku.scroll('滚动弹幕'));
      danmakuService.addLocalDanmaku(Danmaku.top('顶部弹幕'));
      danmakuService.addLocalDanmaku(Danmaku.bottom('底部弹幕'));

      expect(danmakuService.danmakus.length, 3);

      // 关闭顶部弹幕
      danmakuService.setTopVisibility(false);
      expect(danmakuService.danmakus.length, 2); // 只剩下滚动和底部弹幕

      // 关闭滚动弹幕
      danmakuService.setScrollVisibility(false);
      expect(danmakuService.danmakus.length, 1); // 只剩下底部弹幕

      // 关闭底部弹幕
      danmakuService.setBottomVisibility(false);
      expect(danmakuService.danmakus.length, 0); // 没有弹幕了
    });

    test('弹幕设置测试', () {
      // 测试透明度设置
      danmakuService.setOpacity(0.5);
      expect(danmakuService.opacity, 0.5);

      // 测试字体大小设置
      danmakuService.setFontSize(20.0);
      expect(danmakuService.fontSize, 20.0);

      // 测试最大弹幕数量设置
      danmakuService.setMaxCount(50);
      expect(danmakuService.maxCount, 50);
    });

    test('弹幕统计测试', () {
      // 添加不同类型的弹幕
      danmakuService.addLocalDanmaku(Danmaku.scroll('滚动1'));
      danmakuService.addLocalDanmaku(Danmaku.scroll('滚动2'));
      danmakuService.addLocalDanmaku(Danmaku.top('顶部1'));
      danmakuService.addLocalDanmaku(Danmaku.bottom('底部1'));

      final stats = danmakuService.getStatistics();
      
      expect(stats['totalCount'], 4);
      expect(stats['scrollCount'], 2);
      expect(stats['topCount'], 1);
      expect(stats['bottomCount'], 1);
    });

    test('弹幕清空测试', () {
      danmakuService.addLocalDanmaku(Danmaku.scroll('测试弹幕'));
      expect(danmakuService.danmakus.length, 1);

      danmakuService.clearDanmakus();
      expect(danmakuService.danmakus.length, 0);
    });

    test('弹幕重置设置测试', () {
      // 修改设置
      danmakuService.setScrollVisibility(false);
      danmakuService.setOpacity(0.3);
      danmakuService.setFontSize(24.0);

      // 重置设置
      danmakuService.resetToDefaults();

      expect(danmakuService.showScroll, true);
      expect(danmakuService.opacity, 1.0);
      expect(danmakuService.fontSize, 16.0);
    });
  });

  group('弹幕JSON序列化测试', () {
    test('弹幕JSON转换测试', () {
      final originalDanmaku = Danmaku(
        text: 'JSON测试弹幕',
        color: Colors.blue,
        fontSize: 18.0,
        type: DanmakuType.top,
        time: DateTime.now(),
        senderId: 'test_user',
        senderName: '测试用户',
      );

      final json = originalDanmaku.toJson();
      final restoredDanmaku = Danmaku.fromJson(json);

      expect(restoredDanmaku.text, originalDanmaku.text);
      expect(restoredDanmaku.color, originalDanmaku.color);
      expect(restoredDanmaku.fontSize, originalDanmaku.fontSize);
      expect(restoredDanmaku.type, originalDanmaku.type);
      expect(restoredDanmaku.senderId, originalDanmaku.senderId);
      expect(restoredDanmaku.senderName, originalDanmaku.senderName);
    });
  });

  group('弹幕工厂方法测试', () {
    test('滚动弹幕工厂方法', () {
      final danmaku = Danmaku.scroll('滚动弹幕测试');
      
      expect(danmaku.type, DanmakuType.scroll);
      expect(danmaku.text, '滚动弹幕测试');
      expect(danmaku.color, Colors.white);
      expect(danmaku.fontSize, 16.0);
    });

    test('顶部弹幕工厂方法', () {
      final danmaku = Danmaku.top('顶部弹幕测试', color: Colors.red);
      
      expect(danmaku.type, DanmakuType.top);
      expect(danmaku.text, '顶部弹幕测试');
      expect(danmaku.color, Colors.red);
    });

    test('底部弹幕工厂方法', () {
      final danmaku = Danmaku.bottom('底部弹幕测试', fontSize: 20.0);
      
      expect(danmaku.type, DanmakuType.bottom);
      expect(danmaku.text, '底部弹幕测试');
      expect(danmaku.fontSize, 20.0);
    });
  });
}

/// 弹幕系统性能测试
void runPerformanceTests() {
  print('开始弹幕系统性能测试...');

  final stopwatch = Stopwatch()..start();
  final danmakuService = DanmakuService();

  // 测试添加大量弹幕的性能
  const testCount = 1000;
  
  for (int i = 0; i < testCount; i++) {
    final danmaku = Danmaku.scroll(
      '性能测试弹幕 $i',
      color: Colors.primaries[i % Colors.primaries.length],
      fontSize: 14.0 + (i % 5) * 2.0,
    );
    danmakuService.addLocalDanmaku(danmaku);
  }

  stopwatch.stop();
  
  print('添加 $testCount 条弹幕耗时: ${stopwatch.elapsedMilliseconds}ms');
  print('平均每条弹幕耗时: ${stopwatch.elapsedMilliseconds / testCount}ms');
  
  // 测试过滤性能
  stopwatch.reset();
  stopwatch.start();
  
  danmakuService.setScrollVisibility(false);
  danmakuService.setTopVisibility(false);
  
  stopwatch.stop();
  print('弹幕过滤耗时: ${stopwatch.elapsedMicroseconds}μs');
  
  // 测试统计性能
  stopwatch.reset();
  stopwatch.start();
  
  final stats = danmakuService.getStatistics();
  
  stopwatch.stop();
  print('弹幕统计耗时: ${stopwatch.elapsedMicroseconds}μs');
  print('总弹幕数: ${stats['totalCount']}');
}