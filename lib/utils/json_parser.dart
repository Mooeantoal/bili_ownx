/// JSON解析辅助工具类
/// 用于安全地解析API响应，防止类型错误
class JsonParser {
  /// 安全地获取Map类型的值
  static Map<String, dynamic>? getMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  /// 安全地获取List类型的值
  static List<T>? getList<T>(dynamic data, T Function(dynamic) converter) {
    if (data is List) {
      return data.map((item) => converter(item)).toList();
    }
    return null;
  }

  /// 安全地获取字符串值
  static String getString(dynamic data, [String defaultValue = '']) {
    if (data is String) {
      return data;
    }
    return data?.toString() ?? defaultValue;
  }

  /// 安全地获取整数值
  static int getInt(dynamic data, [int defaultValue = 0]) {
    if (data is int) {
      return data;
    }
    if (data is String) {
      return int.tryParse(data) ?? defaultValue;
    }
    return defaultValue;
  }

  /// 安全地获取布尔值
  static bool getBool(dynamic data, [bool defaultValue = false]) {
    if (data is bool) {
      return data;
    }
    if (data is int) {
      return data != 0;
    }
    if (data is String) {
      return data.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  /// 安全地获取嵌套Map的值
  static dynamic getNestedValue(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic current = map;
    
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    
    return current;
  }

  /// 验证API响应格式
  static bool isValidApiResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return false;
    }
    
    final map = data as Map<String, dynamic>;
    return map.containsKey('code') && map['code'] is int;
  }

  /// 获取API响应的消息
  static String getApiMessage(dynamic data, [String defaultMessage = '未知错误']) {
    if (!isValidApiResponse(data)) {
      return defaultMessage;
    }
    
    final map = data as Map<String, dynamic>;
    return map['message']?.toString() ?? map['msg']?.toString() ?? defaultMessage;
  }
}