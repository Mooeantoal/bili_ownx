import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import '../models/comment_info.dart';
import 'package:dio/dio.dart';

/// 评论缓存管理器
class CommentCache {
  static final Map<String, CommentResponse> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 获取缓存的评论
  static CommentResponse? get(String key) {
    final time = _cacheTime[key];
    if (time != null && DateTime.now().difference(time) < _cacheDuration) {
      return _cache[key];
    }
    _cache.remove(key);
    _cacheTime.remove(key);
    return null;
  }

  /// 缓存评论
  static void put(String key, CommentResponse response) {
    _cache[key] = response;
    _cacheTime[key] = DateTime.now();
  }

  /// 清除缓存
  static void clear() {
    _cache.clear();
    _cacheTime.clear();
  }

  /// 清除过期缓存
  static void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTime.entries) {
      if (now.difference(entry.value) >= _cacheDuration) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTime.remove(key);
    }
  }

  /// 生成缓存键
  static String generateKey(String oid, int sort, int page) {
    return '${oid}_${sort}_$page';
  }
}

/// 评论时间格式化工具
class CommentTimeFormatter {
  /// 格式化评论时间
  static String format(int timestamp) {
    final now = DateTime.now();
    final commentTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(commentTime);

    if (difference.inDays > 0) {
      if (difference.inDays >= 365) {
        return '${(difference.inDays / 365).floor()}年前';
      } else if (difference.inDays >= 30) {
        return '${(difference.inDays / 30).floor()}个月前';
      } else {
        return '${difference.inDays}天前';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化为完整日期时间
  static String formatFull(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 评论排序类型
enum CommentSortType {
  hot(3, '热度'),
  time(2, '时间');

  const CommentSortType(this.value, this.displayName);
  
  final int value;
  final String displayName;

  static CommentSortType fromValue(int value) {
    return CommentSortType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CommentSortType.hot,
    );
  }
}

/// 评论操作结果
class CommentOperationResult {
  final bool success;
  final String? message;
  final dynamic data;

  const CommentOperationResult({
    required this.success,
    this.message,
    this.data,
  });

  factory CommentOperationResult.success({String? message, dynamic data}) {
    return CommentOperationResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory CommentOperationResult.failure(String message) {
    return CommentOperationResult(
      success: false,
      message: message,
    );
  }
}

/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Set<Type> retryableExceptions;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.retryableExceptions = const {
      TimeoutException,
      SocketException,
      DioException,
    },
  });

  static const RetryConfig defaultConfig = RetryConfig();

  /// 判断是否应该重试
  bool shouldRetry(dynamic error, int attempt) {
    if (attempt >= maxRetries) return false;
    
    // 检查错误类型是否在重试列表中
    for (final retryableType in retryableExceptions) {
      // 直接类型检查
      if (error.runtimeType == retryableType) {
        return true;
      }
    }
    
    return false;
  }

  /// 获取重试延迟时间
  Duration getRetryDelay(int attempt) {
    // 使用数学pow而不是幂运算符
    final multiplier = math.pow(backoffMultiplier, attempt);
    final delay = Duration(milliseconds: (initialDelay.inMilliseconds * multiplier).round());
    return delay > const Duration(seconds: 30) ? const Duration(seconds: 30) : delay;
  }
}

/// 评论配置
class CommentConfig {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  static const int defaultReplyPageSize = 10;
  static const int maxReplyPageSize = 20;
  
  /// 支持的评论类型
  static const int videoType = 1;
  static const int articleType = 12;
  static const int dynamicType = 17;
  
  /// 支持的排序方式
  static const int sortHot = 3;
  static const int sortTime = 2;
  
  /// 点赞操作类型
  static const int likeAction = 1;
  static const int unlikeAction = 0;
}