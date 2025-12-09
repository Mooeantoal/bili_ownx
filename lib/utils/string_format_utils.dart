/// 字符串格式化工具类
class StringFormatUtils {
  /// 格式化播放量
  static String formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 格式化点赞数
  static String formatLikeCount(int count) {
    return formatPlayCount(count);
  }

  /// 格式化弹幕数
  static String formatDanmakuCount(int count) {
    return formatPlayCount(count);
  }

  /// 格式化收藏数
  static String formatFavoriteCount(int count) {
    return formatPlayCount(count);
  }

  /// 格式化时间戳为相对时间
  static String formatTimestampToRelative(int timestamp) {
    if (timestamp == 0) return '未知时间';
    
    final now = DateTime.now();
    final videoTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(videoTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化视频时长（秒转 分:秒 格式）
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  /// 清理HTML标签
  static String removeHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 清理HTML实体
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// 清理标题（移除HTML标签和实体）
  static String cleanTitle(String title) {
    return decodeHtmlEntities(removeHtmlTags(title));
  }

  /// 格式化UP主名称（处理特殊字符）
  static String cleanAuthorName(String name) {
    return decodeHtmlEntities(name.trim());
  }

  /// 截取文本并添加省略号
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 格式化数字（添加千分位分隔符）
  static String formatNumberWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 检查是否为有效的URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 从文本中提取BV号
  static String? extractBvid(String text) {
    final match = RegExp(r'BV[a-zA-Z0-9]{10}').firstMatch(text);
    return match?.group(0);
  }

  /// 从文本中提取AV号
  static int? extractAid(String text) {
    final match = RegExp(r'av(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1) ?? '') : null;
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}