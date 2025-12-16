import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🚀 快速测试...');
  
  // 测试已知工作视频
  final bvid = 'BV1xx411c7mD';
  
  try {
    final resp = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(Duration(seconds: 10));
    
    final data = jsonDecode(resp.body);
    
    if (data['code'] == 0) {
      print('✅ 视频详情: ${data['data']['title']}');
      
      final cid = data['data']['cid'];
      final playResp = await http.get(
        Uri.parse('https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(Duration(seconds: 10));
      
      final playData = jsonDecode(playResp.body);
      
      if (playData['code'] == 0) {
        print('✅ 播放URL: 正常');
        print('🎉 API修复成功! 视频可以正常播放!');
      } else {
        print('❌ 播放URL失败: ${playData['message']}');
      }
    } else {
      print('❌ 视频详情失败: ${data['message']}');
    }
  } catch (e) {
    print('❌ 异常: $e');
  }
}