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
  
  /// 搜索综合结果 - 使用热门API + 关键词筛选
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
      print('=== 搜索关键词: $keyword ===');
      
      // 方案1: 尝试直接搜索API（可能被限制）
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
        
        if (response.data['code'] == 0) {
          print('✅ 直接搜索API成功');
          return response.data;
        } else {
          print('⚠️  直接搜索API失败: ${response.data['message']}');
        }
      } catch (e) {
        print('⚠️  直接搜索API异常，使用备用方案: $e');
      }
      
      // 方案2: 使用热门API + 关键词筛选
      print('🔄 使用热门API + 关键词筛选...');
      return await _searchFromPopular(keyword, pageNum, pageSize);
      
    } catch (e) {
      print('搜索请求失败: $e');
      rethrow;
    }
  }
  
  /// 从热门视频中搜索相关内容
  static Future<Map<String, dynamic>> _searchFromPopular(
    String keyword,
    int pageNum,
    int pageSize,
  ) async {
    try {
      // 获取热门视频
      final popularUrl = 'https://api.bilibili.com/x/web-interface/popular';
      final response = await _dio.get(popularUrl);
      
      if (response.data['code'] == 0 && response.data['data'] != null) {
        final videos = response.data['data']['list'] as List;
        
        // 关键词匹配
        final relatedVideos = videos.where((video) {
          final title = (video['title'] ?? '').toString().toLowerCase();
          final desc = (video['desc'] ?? '').toString().toLowerCase();
          final author = (video['owner']['name'] ?? '').toString().toLowerCase();
          final searchKeyword = keyword.toLowerCase();
          
          return title.contains(searchKeyword) || 
                 desc.contains(searchKeyword) || 
                 author.contains(searchKeyword);
        }).toList();
        
        print('✅ 从${videos.length}个热门视频中找到${relatedVideos.length}个相关结果');
        
        // 返回搜索结果的格式
        return {
          'code': 0,
          'message': 'success',
          'data': {
            'items': relatedVideos,
            'total': relatedVideos.length,
            'pn': pageNum,
            'ps': pageSize,
            'from_popular': true, // 标记来源
          }
        };
      } else {
        throw Exception('热门API失败: ${response.data['message']}');
      }
    } catch (e) {
      throw Exception('从热门视频搜索失败: $e');
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
