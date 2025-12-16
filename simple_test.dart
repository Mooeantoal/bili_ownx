import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('测试一些知名视频...\n');
  
  // 这些是一些通常存在的视频ID
  final testVideos = [
    'BV1xx411c7mD',  // 一个经典的测试视频
    'BV1uJ411C7cs',  // 另一个测试视频
    'BV1GJ411x7h7',  // 短视频测试
  ];
  
  for (final bvid in testVideos) {
    print('\n=== 测试: $bvid ===');
    
    try {
      final response = await http.get(
        Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.bilibili.com',
        },
      ).timeout(Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      
      if (data['code'] == 0) {
        print('✅ 成功!');
        print('   标题: ${data['data']['title']}');
        print('   作者: ${data['data']['owner']['name']}');
        print('   时长: ${data['data']['duration']}秒');
        
        // 测试播放URL
        final cid = data['data']['cid'];
        print('   CID: $cid');
        
        final playResponse = await http.get(
          Uri.parse('https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid&qn=80&fnval=1'),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com',
          },
        ).timeout(Duration(seconds: 10));
        
        final playData = jsonDecode(playResponse.body);
        if (playData['code'] == 0) {
          print('   ✅ 播放URL获取成功!');
          if (playData['data']['durl'] != null) {
            print('   格式: MP4/FLV');
          } else if (playData['data']['dash'] != null) {
            print('   格式: DASH');
          }
        } else {
          print('   ❌ 播放URL失败: ${playData['message']}');
        }
      } else {
        print('❌ 失败: ${data['code']} - ${data['message']}');
      }
      
    } catch (e) {
      print('❌ 异常: $e');
    }
  }
}