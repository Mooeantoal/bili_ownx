import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    testWidgets('should show error dialog with copy functionality', (WidgetTester tester) async {
      // 构建测试应用
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler.showErrorDialog(
                      context: context,
                      title: '测试错误',
                      error: '这是一个测试错误',
                      stackTrace: StackTrace.current,
                      additionalInfo: '这是附加信息',
                    );
                  },
                  child: const Text('显示错误'),
                );
              },
            ),
          ),
        ),
      );

      // 点击按钮显示错误对话框
      await tester.tap(find.text('显示错误'));
      await tester.pumpAndSettle();

      // 验证对话框已显示
      expect(find.text('测试错误'), findsOneWidget);
      expect(find.text('错误日志 (可选择文本复制)'), findsOneWidget);
      expect(find.text('复制全部'), findsOneWidget);
      expect(find.text('复制并关闭'), findsOneWidget);
    });

    test('formatApiResponseError should handle Map correctly', () {
      final response = {
        'code': 0,
        'data': {'message': 'success'},
        'message': 'ok'
      };

      final formatted = ErrorHandler.formatApiResponseError(response);
      
      expect(formatted, contains('code'));
      expect(formatted, contains('data'));
      expect(formatted, contains('message'));
    });

    test('formatApiResponseError should handle non-Map correctly', () {
      final response = 'simple string response';
      final formatted = ErrorHandler.formatApiResponseError(response);
      
      expect(formatted, equals('simple string response'));
    });
  });
}