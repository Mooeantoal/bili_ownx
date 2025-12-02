import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// 纯 API 测试，不依赖 Flutter UI
void main() async {
  print('=== 战双帕弥什 API 测试 ===\n');
  
  final dio = Dio();
  
  try {
    // 1. 搜索战双帕弥什
    print('🔍 搜索"战双帕弥什"...');
    final searchUrl = _buildSearchUrl('战双帕弥什');
    final searchResponse = await dio.get(searchUrl);
    final searchData = searchResponse.data;
    
    if (searchData['code'] != 0) {
      throw Exception('搜索失败: ${searchData['message']}');
    }
    
    // 2. 解析搜索结果
    final data = searchData['data'];
    List<dynamic> videoList = data['result'] ?? data['items'] ?? [];
    
    if (videoList.isEmpty) {
      throw Exception('没有找到战双帕弥什相关视频');
    }
    
    print('✅ 找到 ${videoList.length} 个战双帕弥什视频\n');
    
    // 3. 测试前3个视频
    final testCount = videoList.length > 3 ? 3 : videoList.length;
    int successCount = 0;
    
    for (int i = 0; i < testCount; i++) {
      try {
        print('--- 测试视频 ${i + 1} ---');
        final videoJson = videoList[i];
        
        // 提取视频信息
        String title = videoJson['title'] ?? videoJson['name'] ?? '未知标题';
        String bvid = videoJson['bvid'] ?? '';
        int aid = videoJson['aid'] ?? videoJson['id'] ?? 0;
        
        // 尝试从 param 字段提取 AV 号
        if (bvid.isEmpty && videoJson['param'] != null && videoJson['goto'] == 'av') {
          aid = int.tryParse(videoJson['param'].toString()) ?? 0;
          print('从 param 字段提取 AV 号: $aid');
        }
        
        print('标题: $title');
        print('BVID: "$bvid"');
        print('AID: $aid');
        
        // 检查是否有有效 ID
        bool hasValidId = bvid.isNotEmpty || aid != 0;
        if (!hasValidId) {
          print('❌ 跳过：视频ID无效');
          continue;
        }
        
        // 获取视频详情
        print('🎬 获取视频详情...');
        final detailUrl = _buildVideoDetailUrl(bvid, aid);
        final detailResponse = await dio.get(detailUrl);
        final detailData = detailResponse.data;
        
        if (detailData['code'] == 0) {
          final videoData = detailData['data'];
          print('✅ 播放测试成功！');
          print('   完整标题: ${videoData['title']}');
          print('   UP主: ${videoData['owner']['name']}');
          print('   播放量: ${videoData['stat']['view']}');
          print('   时长: ${videoData['duration']}秒');
          successCount++;
        } else {
          print('❌ 获取详情失败: ${detailData['message']}');
        }
        
      } catch (e) {
        print('❌ 视频 ${i + 1} 测试失败: $e');
      }
      
      print('');
    }
    
    // 4. 总结
    print('=== 测试总结 ===');
    print('总测试视频数: $testCount');
    print('✅ 成功播放: $successCount');
    print('成功率: ${(successCount / testCount * 100).toStringAsFixed(1)}%');
    
    if (successCount == testCount) {
      print('🎉 所有战双帕弥什视频都能正常播放！');
    } else {
      print('⚠️ 部分视频播放失败，需要进一步检查');
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
  
  // 排序并生成签名
  final sortedParams = Map.fromEntries(
    params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
  );
  
  final queryString = sortedParams.entries
      .where((e) => e.value != null && e.value.toString().isNotEmpty)
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
  
  final sign = md5.convert(utf8.encode('$queryString$appSecret')).toString();
  
  return 'https://api.bilibili.com/x/v2/search/type?${queryString}&sign=$sign';
}

String _buildVideoDetailUrl(String bvid, int aid) {
  if (bvid.isNotEmpty) {
    return 'https://api.bilibili.com/x/web-interface/view?bvid=$bvid';
  } else {
    return 'https://api.bilibili.com/x/web-interface/view?aid=$aid';
  }
}