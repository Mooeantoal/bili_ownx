import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_helper.dart';

/// 视频相关 API
class VideoApi {
  static final Dio _dio = _createDio();

  /// 创建默认的 Dio 实例
  static Dio createDio() => _createDio();

  /// 创建 Dio 实例的私有方法
  static Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com',
        'Origin': 'https://www.bilibili.com',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-site',
        'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"Windows"',
      },
    ));
  }

  /// 获取视频详情
  /// - bvid: BV号 或 aid: AV号
  static Future<Map<String, dynamic>> getVideoDetail({
    String? bvid,
    String? aid, // 改为字符串类型以支持大数值
  }) async {
    if ((bvid == null || bvid.isEmpty) && (aid == null || aid.isEmpty)) {
      throw ArgumentError('bvid 和 aid 必须提供其中一个');
    }

    // 检查 bvid 是否为空字符串
    if (bvid != null && bvid.isEmpty) {
      bvid = null;
    }

    // 检查 aid 是否为空字符串
    if (aid != null && aid.isEmpty) {
      aid = null;
    }

    // 确保至少有一个有效的 ID
    if ((bvid == null || bvid.isEmpty) && (aid == null || aid.isEmpty)) {
      throw ArgumentError('必须提供有效的 bvid 或 aid');
    }

    final params = <String, dynamic>{};
    if (bvid != null && bvid.isNotEmpty) {
      params['bvid'] = bvid;
    } else if (aid != null && aid.isNotEmpty) {
      // 尝试将字符串AID转换为数字，如果失败则直接使用字符串
      final aidInt = int.tryParse(aid);
      params['aid'] = aidInt ?? aid;
    } else {
      throw ArgumentError('没有有效的视频ID');
    }

    // 尝试多个API端点
    final endpoints = [
      'https://api.bilibili.com/x/web-interface/view',  // 主要端点
      'https://api.bilibili.com/x/web-interface/view/detail',  // 备用端点
    ];

    for (int i = 0; i < endpoints.length; i++) {
      try {
        final baseUrl = endpoints[i];
        final queryString = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        final url = '$baseUrl?$queryString';
        
        print('尝试API端点 ${i + 1}/${endpoints.length}: $url');

        final response = await _dio.get(url);
        
        // 检查响应状态和数据
        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'HTTP ${response.statusCode}: ${response.statusMessage}',
          );
        }
        
        // 检查响应数据是否为空
        if (response.data == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: '响应数据为空',
          );
        }
        
        // 检查响应数据是否为字符串（可能是HTML错误页面）
        if (response.data is String) {
          final responseData = response.data as String;
          if (responseData.trim().isEmpty) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '响应内容为空字符串',
            );
          }
          // 如果响应以 < 开头，很可能是HTML错误页面
          if (responseData.trim().startsWith('<')) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '接收到HTML响应而非JSON，可能是API错误页面',
            );
          }
          // 尝试解析字符串为JSON
          try {
            final data = jsonDecode(responseData) as Map<String, dynamic>;
            print('API端点 ${i + 1} 成功响应');
            return data;
          } catch (e) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '无法解析JSON响应: $e\n响应内容: ${responseData.substring(0, responseData.length > 200 ? 200 : responseData.length)}...',
            );
          }
        }
        
        print('API端点 ${i + 1} 成功响应');
        return response.data;
      } catch (e) {
        print('API端点 ${i + 1} 失败: $e');
        if (i == endpoints.length - 1) {
          // 最后一个端点也失败了，抛出异常
          final errorInfo = {
            'type': 'DioException',
            'message': e.toString(),
            'requestParams': params,
          };
          print('所有API端点都失败，详细错误信息: $errorInfo');
          rethrow;
        }
        // 继续尝试下一个端点
        continue;
      }
    }
    
    throw Exception('未知的API错误');
  }

  /// 获取视频播放地址
  /// - bvid: BV号
  /// - cid: 分P的cid
  /// - qn: 画质 (16:流畅 32:清晰 64:高清 80:超清 112:高清1080P 116:高清1080P60)
  /// - fnval: 返回格式 (1:mp4/flv, 16:dash)
  static Future<Map<String, dynamic>> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 1, // 默认返回 MP4/FLV 格式，画质切换更明显
  }) async {
    // 验证参数
    if (bvid.isEmpty) {
      throw ArgumentError('BVID 不能为空');
    }
    
    if (cid <= 0) {
      throw ArgumentError('CID 必须大于 0，当前值: $cid。可能原因：视频已被删除、正在审核中或API返回数据异常。');
    }
    
    print('请求播放地址: bvid=$bvid, cid=$cid, qn=$qn, fnval=$fnval');
    
    final params = {
      'bvid': bvid,
      'cid': cid,
      'qn': qn,
      'fnval': fnval,
      'fourk': 1,
    };

    // 尝试多个API端点
    final endpoints = [
      'https://api.bilibili.com/x/player/playurl',  // 主要端点
      'https://api.bilibili.com/x/player/playurljson',  // JSON格式备用端点
    ];

    for (int i = 0; i < endpoints.length; i++) {
      try {
        final baseUrl = endpoints[i];
        final queryString = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        final url = '$baseUrl?$queryString';
        
        print('尝试播放URL端点 ${i + 1}/${endpoints.length}: $url');

        final response = await _dio.get(url);
        
        // 检查响应状态和数据
        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'HTTP ${response.statusCode}: ${response.statusMessage}',
          );
        }
        
        // 检查响应数据是否为空
        if (response.data == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: '播放地址响应数据为空',
          );
        }
        
        // 检查响应数据是否为字符串（可能是HTML错误页面）
        if (response.data is String) {
          final responseData = response.data as String;
          if (responseData.trim().isEmpty) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '播放地址响应内容为空字符串',
            );
          }
          // 如果响应以 < 开头，很可能是HTML错误页面
          if (responseData.trim().startsWith('<')) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '接收到HTML响应而非JSON，可能是API错误页面',
            );
          }
          // 尝试解析字符串为JSON
          try {
            final data = jsonDecode(responseData) as Map<String, dynamic>;
            return _processPlayUrlResponse(data, i + 1);
          } catch (e) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: '无法解析播放地址JSON响应: $e\n响应内容: ${responseData.substring(0, responseData.length > 200 ? 200 : responseData.length)}...',
            );
          }
        }
        
        return _processPlayUrlResponse(response.data, i + 1);
      } catch (e) {
        print('播放URL端点 ${i + 1} 失败: $e');
        if (i == endpoints.length - 1) {
          // 最后一个端点也失败了，抛出异常
          final errorInfo = {
            'type': 'DioException',
            'message': e.toString(),
            'requestParams': params,
          };
          print('所有播放URL端点都失败，详细错误信息: $errorInfo');
          rethrow;
        }
        // 继续尝试下一个端点
        continue;
      }
    }
    
    throw Exception('未知的播放URL API错误');
  }

  /// 处理播放URL响应数据
  static Map<String, dynamic> _processPlayUrlResponse(Map<String, dynamic> data, int endpointIndex) {
    print('播放URL端点 $endpointIndex 成功响应');
    
    // 打印响应信息用于调试
    if (data['code'] == 0) {
      final playData = data['data'];
      print('API 响应成功:');
      
      if (playData['durl'] != null) {
        final durl = playData['durl'][0];
        print('- 格式: MP4/FLV');
        print('- 文件大小: ${(durl['size'] / 1024 / 1024).toStringAsFixed(2)} MB');
        print('- 画质: ${playData['quality'] ?? '未知'}');
      } else if (playData['dash'] != null) {
        print('- 格式: DASH');
        final videos = playData['dash']['video'] as List?;
        if (videos != null) {
          print('- 可用视频流: ${videos.length} 个');
        }
      }
      
      if (playData['accept_quality'] != null) {
        print('- 支持的画质: ${playData['accept_quality']}');
      }
    } else {
      print('API 响应错误: ${data['message']}');
    }
    
    return data;
  }

  /// 获取视频分P列表
  /// - bvid: BV号 或 aid: AV号
  static Future<List<Map<String, dynamic>>> getVideoParts({
    String? bvid,
    String? aid, // 改为字符串类型
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
