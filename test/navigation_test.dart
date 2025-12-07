import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/pages/main_page.dart';

void main() {
  group('底部导航栏测试', () {
    testWidgets('应该显示所有导航项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(),
        ),
      );

      // 验证底部导航栏存在
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 验证所有导航项
      expect(find.text('搜索'), findsOneWidget);
      expect(find.text('下载'), findsOneWidget);
      expect(find.text('元数据'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // 验证图标
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('应该能够切换页面', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(),
        ),
      );

      // 初始状态应该在搜索页面
      expect(find.text('Bilibili 搜索'), findsOneWidget);

      // 点击下载导航项
      await tester.tap(find.text('下载'));
      await tester.pumpAndSettle();

      // 验证导航栏状态更新
      final BottomNavigationBar navBar = tester.widget(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, 1);

      // 点击设置导航项
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证导航栏状态更新
      final BottomNavigationBar navBar2 = tester.widget(find.byType(BottomNavigationBar));
      expect(navBar2.currentIndex, 3);
    });
  });
}