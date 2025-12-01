import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
    
    // 添加时间戳
    errorBuffer.writeln('错误时间: ${DateTime.now().toIso8601String()}');
    errorBuffer.writeln('');
    
    errorBuffer.writeln('错误类型: ${error.runtimeType}');
    errorBuffer.writeln('错误信息: $error');
    
    if (additionalInfo != null) {
      errorBuffer.writeln('\n附加信息:');
      errorBuffer.writeln(additionalInfo);
    }
    
    if (stackTrace != null) {
      errorBuffer.writeln('\n堆栈跟踪:');
      errorBuffer.writeln(stackTrace.toString());
    }
    
    // 添加系统信息
    errorBuffer.writeln('\n系统信息:');
    errorBuffer.writeln('- 平台: ${Theme.of(context).platform.name}');
    errorBuffer.writeln('- Flutter版本: ${_getFlutterVersion()}');
    
    final String errorDetails = errorBuffer.toString();
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // 内容区域
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '错误日志 (可选择文本复制)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: errorDetails));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ 错误信息已复制到剪贴板'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('复制全部'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                errorDetails,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 底部按钮
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: errorDetails));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ 错误信息已复制到剪贴板'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制并关闭'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 获取Flutter版本信息
  static String _getFlutterVersion() {
    try {
      return 'Flutter ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'Unknown')}';
    } catch (e) {
      return 'Unknown';
    }
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