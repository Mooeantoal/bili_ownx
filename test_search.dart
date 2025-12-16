import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 测试B站搜索功能');
  print('==================');
  
  final keyword = '七实 芒星之迹';
  
  print('🔑 搜索关键词: $keyword');
  print('');
  
  // 测试多个搜索端点
  final searchEndpoints = [
    {
      'name': 'Web搜索API',
      'url': 'https://api.bilibili.com/x/web-interface/search/all/v2',
      'params': {
        'keyword': keyword,
        'page': 1,
        'page_size': 10,
        'platform': 'pc',
      }
    },
    {
      'name': 'App搜索API', 
      'url': 'https://app.bilibili.com/x/v2/search',
      'params': {
        'keyword': keyword,
        'pn': 1,
        'ps': 10,
        'order': 'totalrank',
        'duration': 0,
        'rid': 0,
      }
    },
    {
      'name': '简化搜索API',
      'url': 'https://api.bilibili.com/x/web-interface/search/type',
      'params': {
        'search_type': 'video',
        'keyword': keyword,
        'page': 1,
        'page_size': 10,
      }
    }
  ];
  
  for (int i = 0; i < searchEndpoints.length; i++) {
    final endpoint = searchEndpoints[i];
    print('📍 测试 ${i + 1}/${searchEndpoints.length}: ${endpoint['name']}');
    print('🔗 URL: ${endpoint['url']}');
    
    try {
      // 构建查询字符串
      final params = endpoint['params'] as Map<String, dynamic>;
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final fullUrl = '${endpoint['url']}?$queryString';
      
      print('🌐 完整请求: $fullUrl');
      
      final response = await http.get(
        Uri.parse(fullUrl),
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
      ).timeout(Duration(seconds: 15));
      
      print('📊 响应状态: ${response.statusCode}');
      print('📏 响应长度: ${response.body.length} 字节');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          if (data is Map && data.containsKey('code')) {
            final code = data['code'];
            final message = data['message'] ?? '无消息';
            
            print('🔢 API码: $code');
            print('💬 消息: $message');
            
            if (code == 0 && data['data'] != null) {
              final responseData = data['data'];
              print('✅ 搜索成功!');
              
              // 尝试提取视频列表
              List? videoList = [];
              
              if (responseData is Map) {
                // 检查不同的可能字段
                if (responseData['result'] != null) {
                  final result = responseData['result'];
                  if (result is Map && result['video'] != null) {
                    videoList = result['video'] as List?;
                  } else if (result is List) {
                    videoList = result;
                  }
                } else if (responseData['items'] != null) {
                  videoList = responseData['items'] as List?;
                } else if (responseData['list'] != null) {
                  videoList = responseData['list'] as List?;
                } else if (responseData['vlist'] != null) {
                  videoList = responseData['vlist'] as List?;
                }
              }
              
              if (videoList != null && videoList.isNotEmpty) {
                print('📺 找到 ${videoList.length} 个视频结果:');
                
                for (int j = 0; j < videoList.length && j < 3; j++) {
                  final video = videoList[j] as Map;
                  final title = video['title'] ?? video['name'] ?? '无标题';
                  final author = video['author'] ?? video['uname'] ?? video['owner']?['name'] ?? '未知作者';
                  final bvid = video['bvid'] ?? '无BVID';
                  final aid = video['aid'] ?? '无AID';
                  
                  print('   ${j + 1}. 📝 $title');
                  print('      👤 $author');
                  print('      🆔 BVID: $bvid');
                  print('      🆔 AID: $aid');
                  
                  // 如果有有效的BVID，测试播放
                  if (bvid != null && bvid != '无BVID' && bvid.toString().startsWith('BV')) {
                    print('      🔍 测试播放: $bvid');
                    await testVideoPlayback(bvid.toString());
                    print('      ✅ 播放测试完成');
                  }
                  print('');
                }
              } else {
                print('⚠️  未找到视频结果');
                print('📋 可用字段: ${responseData.keys.toList()}');
              }
            } else {
              print('❌ API返回错误: $code - $message');
            }
          } else {
            print('❌ 响应格式异常');
          }
        } catch (e) {
          print('❌ JSON解析失败: $e');
          print('📄 响应前200字符: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      } else {
        print('❌ HTTP请求失败: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ 请求异常: $e');
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    
    // 避免请求过于频繁
    if (i < searchEndpoints.length - 1) {
      await Future.delayed(Duration(seconds: 2));
    }
  }
  
  print('🏁 搜索测试完成');
}

/// 测试视频播放
Future<void> testVideoPlayback(String bvid) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.bilibili.com',
      },
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0 && data['data'] != null) {
        final videoData = data['data'];
        final cid = videoData['cid'];
        final title = videoData['title'];
        
        print('         📹 视频信息: $title (CID: $cid)');
        
        // 获取播放URL
        final playResponse = await http.get(
          Uri.parse('https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid&qn=80&fnval=1'),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com',
          },
        ).timeout(Duration(seconds: 10));
        
        if (playResponse.statusCode == 200) {
          final playData = jsonDecode(playResponse.body);
          if (playData['code'] == 0) {
            print('         ✅ 播放URL获取成功');
          } else {
            print('         ❌ 播放URL失败: ${playData['message']}');
          }
        } else {
          print('         ❌ 播放URL请求失败: ${playResponse.statusCode}');
        }
      } else {
        print('         ❌ 视频详情失败: ${data['message']}');
      }
    } else {
      print('         ❌ 视频详情请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print('         ❌ 播放测试异常: $e');
  }
}