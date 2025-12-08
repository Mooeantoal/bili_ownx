/// 网络信息模型
class NetworkInfo {
  final bool isConnected;
  final String connectionType;
  final String? ssid;
  final int? strength;
  final DateTime lastUpdated;

  const NetworkInfo({
    required this.isConnected,
    required this.connectionType,
    this.ssid,
    this.strength,
    required this.lastUpdated,
  });

  /// 创建网络信息
  factory NetworkInfo.create({
    required bool isConnected,
    required String connectionType,
    String? ssid,
    int? strength,
  }) {
    return NetworkInfo(
      isConnected: isConnected,
      connectionType: connectionType,
      ssid: ssid,
      strength: strength,
      lastUpdated: DateTime.now(),
    );
  }

  /// 网络状态描述
  String get statusDescription {
    if (!isConnected) return '无网络连接';
    
    switch (connectionType) {
      case 'wifi':
        return 'WiFi连接${ssid != null ? ' - $ssid' : ''}${strength != null ? ' ($strength%)' : ''}';
      case 'mobile':
        return '移动网络连接';
      case 'ethernet':
        return '有线网络连接';
      default:
        return '网络已连接';
    }
  }

  /// 是否是稳定网络
  bool get isStableConnection {
    return isConnected && (connectionType == 'wifi' || connectionType == 'ethernet');
  }

  /// 网络质量评估
  NetworkQuality get quality {
    if (!isConnected) return NetworkQuality.none;
    
    if (connectionType == 'wifi') {
      if (strength != null) {
        if (strength! >= 70) return NetworkQuality.excellent;
        if (strength! >= 50) return NetworkQuality.good;
        if (strength! >= 30) return NetworkQuality.fair;
        return NetworkQuality.poor;
      }
      return NetworkQuality.good;
    }
    
    if (connectionType == 'mobile') {
      return NetworkQuality.fair;
    }
    
    if (connectionType == 'ethernet') {
      return NetworkQuality.excellent;
    }
    
    return NetworkQuality.unknown;
  }
}

/// 网络质量枚举
enum NetworkQuality {
  none,      // 无网络
  poor,      // 差
  fair,      // 一般
  good,      // 良好
  excellent, // 优秀
  unknown,   // 未知
}

/// 网络质量扩展方法
extension NetworkQualityExtension on NetworkQuality {
  String get displayName {
    switch (this) {
      case NetworkQuality.none:
        return '无网络';
      case NetworkQuality.poor:
        return '网络质量差';
      case NetworkQuality.fair:
        return '网络质量一般';
      case NetworkQuality.good:
        return '网络质量良好';
      case NetworkQuality.excellent:
        return '网络质量优秀';
      case NetworkQuality.unknown:
        return '网络质量未知';
    }
  }

  String get emoji {
    switch (this) {
      case NetworkQuality.none:
        return '🔴';
      case NetworkQuality.poor:
        return '🟠';
      case NetworkQuality.fair:
        return '🟡';
      case NetworkQuality.good:
        return '🟢';
      case NetworkQuality.excellent:
        return '💚';
      case NetworkQuality.unknown:
        return '⚪';
    }
  }
}