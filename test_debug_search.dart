import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// 调试搜索API响应结构
void main() async {
  print('=== 调试战双帕弥什搜索 ===\n');
  
  final dio = Dio();
  
  try {
    // 搜索战双帕弥什
    print('🔍 搜索"战双帕弥什"...');
    final searchUrl = _buildSearchUrl('战双帕弥什');
    print('搜索URL: $searchUrl');
    
    final searchResponse = await dio.get(searchUrl);
    final searchData = searchResponse.data;
    
    print('搜索响应状态: ${searchData['code']}');
    print('搜索响应消息: ${searchData['message']}');
    
    if (searchData['code'] != 0) {
      print('❌ 搜索失败');
      return;
    }
    
    // 调试数据结构
    print('\n📊 调试搜索数据结构:');
    print('所有顶级字段: ${searchData.keys.toList()}');
    
    if (searchData['data'] != null) {
      final data = searchData['data'];
      print('data字段类型: ${data.runtimeType}');
      print('data字段内容: ${data.keys.toList()}');
      
      // 检查是否有 result 字段
      if (data.containsKey('result')) {
        final result = data['result'];
        print('result字段类型: ${result.runtimeType}');
        if (result is List) {
          print('result列表长度: ${result.length}');
          if (result.isNotEmpty) {
            final firstItem = result.first;
            if (firstItem is Map) {
              print('第一个result项目的字段: ${firstItem.keys.toList()}');
            }
          }
        }
      } else {
        print('❌ 没有result字段');
        
        // 尝试其他可能的字段
        for (final key in data.keys) {
          final value = data[key];
          if (value is List && value.isNotEmpty) {
            print('发现列表字段: $key, 长度: ${value.length}');
            if (value.first is Map) {
              final firstItem = value.first as Map;
              print('第一个项目的字段: ${firstItem.keys.toList()}');
              
              // 检查是否包含视频相关字段
              final hasVideoFields = firstItem.keys.any((k) => 
                ['title', 'bvid', 'aid', 'author', 'cover', 'play'].contains(k));
              
              if (hasVideoFields) {
                print('✅ $key 包含视频信息');
                
                // 测试第一个视频
                final videoJson = firstItem;
                String title = videoJson['title'] ?? videoJson['name'] ?? '未知标题';
                String bvid = videoJson['bvid'] ?? '';
                int aid = videoJson['aid'] ?? videoJson['id'] ?? 0;
                
                print('\n🎬 测试第一个视频:');
                print('标题: $title');
                print('BVID: "$bvid"');
                print('AID: $aid');
                
                // 尝试获取视频详情
                if (bvid.isNotEmpty || aid != 0) {
                  final detailUrl = _buildVideoDetailUrl(bvid, aid);
                  print('详情URL: $detailUrl');
                  
                  try {
                    final detailResponse = await dio.get(detailUrl);
                    final detailData = detailResponse.data;
                    
                    if (detailData['code'] == 0) {
                      print('✅ 视频详情获取成功!');
                      final videoData = detailData['data'];
                      print('完整标题: ${videoData['title']}');
                      print('UP主: ${videoData['owner']['name']}');
                      print('播放量: ${videoData['stat']['view']}');
                    } else {
                      print('❌ 获取详情失败: ${detailData['message']}');
                    }
                  } catch (e) {
                    print('❌ 获取详情异常: $e');
                  }
                } else {
                  print('❌ 视频ID无效');
                }
                
                break;
              }
            }
          }
        }
      }
    }
    
  } catch (e) {
    print('❌ 测试过程出错: $e');
  }
  
  print('\n=== 测试完成 ===');
}

String _buildSearchUrl(String keyword) {
  const appKey = 'dfca71928277209b';
  const appSecret = 'b5475a8825547a4fc26c7d518eaaa02e';
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  final params = {
    'keyword': keyword,
    'pn': 1,
    'ps': 10,
    'appkey': appKey,
    'platform': 'android',
    'channel': 'bili',
    'mobi_app': 'android_hd',
    'build': 1450000,
    'c_locale': 'zh_CN',
    's_locale': 'zh_CN',
    'device': 'android',
    'buvid': 'XY${DateTime.now().millisecondsSinceEpoch}',
    'ts': timestamp,
  };
  
  final sortedParams = Map.fromEntries(
    params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
  );
  
  final queryString = sortedParams.entries
      .where((e) => e.value != null && e.value.toString().isNotEmpty)
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
  
  final sign = md5.convert(utf8.encode('$queryString$appSecret')).toString();
  
  return 'https://api.bilibili.com/x/web-interface/search/type?${queryString}&sign=$sign';
}

String _buildVideoDetailUrl(String bvid, int aid) {
  if (bvid.isNotEmpty) {
    return 'https://api.bilibili.com/x/web-interface/view?bvid=$bvid';
  } else {
    return 'https://api.bilibili.com/x/web-interface/view?aid=$aid';
  }
}