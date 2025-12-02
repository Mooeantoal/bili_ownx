import 'package:dio/dio.dart';
import 'api_helper.dart';

/// 视频相关 API
class VideoApi {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Referer': 'https://www.bilibili.com',
      'Origin': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
    },
  ));

  /// 获取视频详情
  /// - bvid: BV号 或 aid: AV号
  static Future<Map<String, dynamic>> getVideoDetail({
    String? bvid,
    int? aid,
  }) async {
    if (bvid == null && aid == null) {
      throw ArgumentError('bvid 和 aid 必须提供其中一个');
    }

    try {
      final params = <String, dynamic>{};
      if (bvid != null) {
        params['bvid'] = bvid;
      } else {
        params['aid'] = aid;
      }

      final url = ApiHelper.buildUrl(
        'https://api.bilibili.com/x/web-interface/view',
        params,
      );

      final response = await _dio.get(url);
      return response.data;
    } on DioException catch (e) {
      final errorInfo = {
        'type': 'DioException',
        'message': e.message,
        'responseCode': e.response?.statusCode,
        'responseData': e.response?.data,
        'requestUrl': e.requestOptions.uri.toString(),
        'requestHeaders': e.requestOptions.headers,
        'requestParams': e.requestOptions.queryParameters,
      };
      print('获取视频详情失败: ${e.message}');
      print('详细错误信息: $errorInfo');
      rethrow;
    }
  }

  /// 获取视频播放地址
  /// - bvid: BV号
  /// - cid: 分P的cid
  /// - qn: 画质 (16:流畅 32:清晰 64:高清 80:超清 112:高清1080P 116:高清1080P60)
  /// - fnval: 返回格式 (1:mp4 16:dash)
  static Future<Map<String, dynamic>> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 16, // 默认返回 DASH 格式
  }) async {
    try {
      final url = ApiHelper.buildUrl(
        'https://api.bilibili.com/x/player/playurl',
        {
          'bvid': bvid,
          'cid': cid,
          'qn': qn,
          'fnval': fnval,
          'fourk': 1,
        },
      );

      final response = await _dio.get(url);
      return response.data;
    } on DioException catch (e) {
      final errorInfo = {
        'type': 'DioException',
        'message': e.message,
        'responseCode': e.response?.statusCode,
        'responseData': e.response?.data,
        'requestUrl': e.requestOptions.uri.toString(),
        'requestHeaders': e.requestOptions.headers,
        'requestParams': e.requestOptions.queryParameters,
      };
      print('获取播放地址失败: ${e.message}');
      print('详细错误信息: $errorInfo');
      rethrow;
    }
  }

  /// 获取视频分P列表
  /// - bvid: BV号 或 aid: AV号
  static Future<List<Map<String, dynamic>>> getVideoParts({
    String? bvid,
    int? aid,
  }) async {
    final detail = await getVideoDetail(bvid: bvid, aid: aid);
    
    if (detail['code'] == 0 && detail['data'] != null) {
      final pages = detail['data']['pages'] as List?;
      if (pages != null) {
        return pages.cast<Map<String, dynamic>>();
      }
    }
    
    return [];
  }
}
