import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// 错误处理器
class ErrorHandler {
  /// 获取错误消息
  static String getMessage(dynamic error) {
    if (error is DioException) {
      return _getDioErrorMessage(error);
    } else if (error is Exception) {
      return error.toString();
    } else {
      return '未知错误: $error';
    }
  }

  /// 获取Dio错误消息
  static String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络设置';
      case DioExceptionType.sendTimeout:
        return '发送请求超时';
      case DioExceptionType.receiveTimeout:
        return '接收数据超时';
      case DioExceptionType.badResponse:
        return _getResponseErrorMessage(error.response);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') == true) {
          return '网络连接失败，请检查网络设置';
        }
        return error.error?.toString() ?? '网络请求失败';
    }
  }

  /// 获取响应错误消息
  static String _getResponseErrorMessage(Response? response) {
    if (response == null) {
      return '服务器响应异常';
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // 尝试从响应中提取错误消息
    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['msg'] != null) {
        return data['msg'].toString();
      }
      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    // 根据状态码返回通用错误消息
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权访问，请登录';
      case 403:
        return '访问被拒绝';
      case 404:
        return '请求的资源不存在';
      case 429:
        return '请求过于频繁，请稍后再试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂时不可用';
      case 504:
        return '网关超时';
      default:
        return '服务器错误 ($statusCode)';
    }
  }

  /// 判断是否为网络错误
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ].contains(error.type);
    }
    return false;
  }

  /// 判断是否为认证错误
  static bool isAuthError(dynamic error) {
    if (error is DioException && error.response != null) {
      return error.response!.statusCode == 401;
    }
    return false;
  }

  /// 判断是否为服务器错误
  static bool isServerError(dynamic error) {
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode!;
      return statusCode >= 500;
    }
    return false;
  }

  /// 判断是否为客户端错误
  static bool isClientError(dynamic error) {
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode!;
      return statusCode >= 400 && statusCode < 500;
    }
    return false;
  }

  /// 获取错误类型
  static ErrorType getErrorType(dynamic error) {
    if (isNetworkError(error)) {
      return ErrorType.network;
    } else if (isAuthError(error)) {
      return ErrorType.auth;
    } else if (isServerError(error)) {
      return ErrorType.server;
    } else if (isClientError(error)) {
      return ErrorType.client;
    } else {
      return ErrorType.unknown;
    }
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog({
    required BuildContext context,
    String title = '错误',
    required String error,
    String? stackTrace,
    String? additionalInfo,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error),
              if (additionalInfo != null) ...[
                const SizedBox(height: 16),
                Text(
                  additionalInfo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (stackTrace != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '详细信息:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stackTrace,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 格式化API响应错误
  static String formatApiResponseError(dynamic response) {
    if (response == null) {
      return '无响应数据';
    }

    if (response is Response) {
      final statusCode = response.statusCode ?? 0;
      final data = response.data;

      String result = '状态码: $statusCode';

      if (data != null) {
        if (data is Map<String, dynamic>) {
          final message = data['message'] ?? data['msg'] ?? data['error'];
          if (message != null) {
            result += '\n错误信息: $message';
          }
          if (data['code'] != null) {
            result += '\n错误代码: ${data['code']}';
          }
        } else {
          result += '\n响应数据: ${data.toString()}';
        }
      }

      return result;
    }

    return response.toString();
  }
}

/// 错误类型枚举
enum ErrorType {
  network,  // 网络错误
  auth,     // 认证错误
  server,   // 服务器错误
  client,   // 客户端错误
  unknown,  // 未知错误
}

/// 错误类型扩展
extension ErrorTypeExtension on ErrorType {
  String get displayName {
    switch (this) {
      case ErrorType.network:
        return '网络错误';
      case ErrorType.auth:
        return '认证错误';
      case ErrorType.server:
        return '服务器错误';
      case ErrorType.client:
        return '请求错误';
      case ErrorType.unknown:
        return '未知错误';
    }
  }

  String get icon {
    switch (this) {
      case ErrorType.network:
        return '🌐';
      case ErrorType.auth:
        return '🔒';
      case ErrorType.server:
        return '🖥️';
      case ErrorType.client:
        return '❌';
      case ErrorType.unknown:
        return '⚠️';
    }
  }
}

/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration delay;
  final Duration backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 1),
    this.backoffMultiplier = const Duration(seconds: 2),
  });

  /// 默认重试配置
  static const RetryConfig defaultConfig = RetryConfig();

  /// 网络错误重试配置
  static const RetryConfig networkConfig = RetryConfig(
    maxRetries: 5,
    delay: Duration(seconds: 2),
    backoffMultiplier: Duration(seconds: 2),
  );

  /// 服务器错误重试配置
  static const RetryConfig serverConfig = RetryConfig(
    maxRetries: 2,
    delay: Duration(seconds: 3),
  );

  /// 获取下一次重试延迟
  Duration getRetryDelay(int attempt) {
    return Duration(
      milliseconds: (delay.inMilliseconds * (attempt + 1) * 
          (backoffMultiplier.inMilliseconds ~/ 1000)).toInt(),
    );
  }

  /// 判断是否应该重试
  bool shouldRetry(dynamic error, int currentAttempt) {
    if (currentAttempt >= maxRetries) {
      return false;
    }

    final errorType = ErrorHandler.getErrorType(error);

    switch (errorType) {
      case ErrorType.network:
        return true; // 网络错误总是重试
      case ErrorType.server:
        return true; // 服务器错误重试
      case ErrorType.client:
        return false; // 客户端错误不重试
      case ErrorType.auth:
        return false; // 认证错误不重试
      case ErrorType.unknown:
        return currentAttempt < 2; // 未知错误最多重试2次
    }
  }
}
