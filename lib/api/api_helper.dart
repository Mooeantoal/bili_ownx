import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Bilibili API Helper - 处理 API 签名和请求参数
class ApiHelper {
  // APP KEY 和 SECRET (来自 bilimiao Android HD 版)
  static const String appKey = 'dfca71928277209b';
  static const String appSecret = 'b5475a8825547a4fc26c7d518eaaa02e';
  
  // 其他常量
  static const String platform = 'android';
  static const String channel = 'bili';
  static const String mobiApp = 'android_hd';
  static const int buildVersion = 1450000;
  static const String locale = 'zh_CN';
  
  /// 获取当前时间戳（秒）
  static int getTimeSpan() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  
  /// 计算 MD5
  static String getMD5(String input) {
    var bytes = utf8.encode(input);
    var digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// 生成签名
  /// 1. 对参数按 key 排序
  /// 2. 拼接成 key=value&key2=value2 格式
  /// 3. 末尾拼接 appSecret
  /// 4. 计算 MD5
  static String generateSign(Map<String, dynamic> params) {
    // 排序参数
    var sortedKeys = params.keys.toList()..sort();
    
    // 拼接参数
    var paramStr = sortedKeys
        .where((key) => params[key] != null && params[key].toString().isNotEmpty)
        .map((key) => '$key=${Uri.encodeComponent(params[key].toString())}')
        .join('&');
    
    // 拼接 secret 并计算 MD5
    return getMD5(paramStr + appSecret);
  }
  
  /// 创建带签名的参数
  static Map<String, dynamic> createParams(Map<String, dynamic> customParams) {
    final params = <String, dynamic>{
      'appkey': appKey,
      'platform': platform,
      'channel': channel,
      'mobi_app': mobiApp,
      'build': buildVersion,
      'c_locale': locale,
      'ts': getTimeSpan(),
      // 添加一些必要的默认参数
      'device': 'android',
      'mobi_app': 'android_hd',
      'buvid': 'XY${DateTime.now().millisecondsSinceEpoch}',
      'statistics': '{"appId":1,"platform":3,"version":"7.75.0","abtest":""}',
    };
    // 合并自定义参数
    if (customParams.isNotEmpty) {
      params.addAll(customParams);
    }
    
    // 生成签名
    params['sign'] = generateSign(params);
    
    return params;
  }
  
  /// 构建完整 URL
  static String buildUrl(String baseUrl, Map<String, dynamic> params) {
    final signedParams = createParams(params);
    final queryString = signedParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }
}
