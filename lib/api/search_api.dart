import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_helper.dart';

/// 搜索相关 API
class SearchApi {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: kIsWeb ? {} : {
      // Web 平台浏览器会拒绝这些请求头，仅在移动平台使用
      'User-Agent': 'Mozilla/5.0 BiliDroid/7.60.0 (bbcallen@gmail.com) os/android model/Mi 10 mobi_app/android build/7600300 channel/master innerVer/7600310 osVer/13 network/2',
      'Referer': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
    },
  ));
  
  /// 搜索综合结果
  /// - keyword: 关键词
  /// - pageNum: 页码
  /// - pageSize: 每页数量
  /// - order: 排序方式 (totalrank, pubdate, click, scores)
  /// - duration: 时长筛选 (0:全部, 1:10分钟以下, 2:10-30分钟, 3:30-60分钟, 4:60分钟以上)
  /// - rid: 分区ID (0:全部)
  static Future<Map<String, dynamic>> searchArchive({
    required String keyword,
    int pageNum = 1,
    int pageSize = 20,
    String order = 'totalrank',
    int duration = 0,
    int rid = 0,
  }) async {
    try {
      final url = ApiHelper.buildUrl(
        'https://app.bilibili.com/x/v2/search',
        {
          'keyword': keyword,
          'pn': pageNum,
          'ps': pageSize,
          'order': order,
          'duration': duration,
          'rid': rid,
        },
      );
      
 final response = await _dio.get(url);
      return response.data;
    } on DioException catch (e) {
      print('搜索请求失败: ${e.message}');
      rethrow;
    }
  }
  
  /// 搜索建议（关键词提示）
  static Future<List<String>> getSuggestions(String keyword) async {
    try {
      final url = 'https://s.search.bilibili.com/main/suggest?'
          'suggest_type=accurate&sub_type=tag&main_ver=v1&term=$keyword';
      
      final response = await _dio.get(url);
      
      if (response.data['result'] != null && response.data['result']['tag'] != null) {
        return (response.data['result']['tag'] as List)
            .map((e) => e['value'].toString())
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('获取搜索建议失败: ${e.message}');
      return [];
    }
  }
}
