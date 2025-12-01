import 'package:flutter/material.dart';
import 'dart:convert';

/// 错误处理工具类
class ErrorHandler {
  /// 显示错误对话框，包含详细错误信息和复制功能
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required Object error,
    StackTrace? stackTrace,
    String? additionalInfo,
  }) async {
    final StringBuffer errorBuffer = StringBuffer();
    
    errorBuffer.writeln('错误信息: $error');
    
    if (additionalInfo != null) {
      errorBuffer.writeln('\n附加信息:');
      errorBuffer.writeln(additionalInfo);
    }
    
    if (stackTrace != null) {
      errorBuffer.writeln('\n堆栈跟踪:');
      errorBuffer.writeln(stackTrace.toString());
    }
    
    final String errorDetails = errorBuffer.toString();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('详细错误信息:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      errorDetails,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: errorDetails));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('错误信息已复制到剪贴板')),
                );
              },
              child: const Text('复制'),
            ),
          ],
        );
      },
    );
  }
  
  /// 格式化API响应错误
  static String formatApiResponseError(dynamic response) {
    try {
      if (response is Map<String, dynamic>) {
        return JsonEncoder.withIndent('  ').convert(response);
      } else {
        return response.toString();
      }
    } catch (e) {
      return response.toString();
    }
  }
}