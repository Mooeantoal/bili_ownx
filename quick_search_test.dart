import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 快速搜索测试');
  print('=================');
  
  try {
    // 获取热门视频
    final resp = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/popular'),
      headers: {'User-Agent': 'Mozilla/5.0', 'Referer': 'https://www.bilibili.com/'},
    ).timeout(Duration(seconds: 8));
    
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['code'] == 0) {
        final videos = data['data']['list'] as List;
        
        // 搜索游戏相关视频
        final gameVideos = videos.where((v) {
          final title = (v['title'] ?? '').toString().toLowerCase();
          return title.contains('游戏') || title.contains('pv') || title.contains('定档');
        }).take(2).toList();
        
        print('✅ 找到 ${gameVideos.length} 个游戏相关视频:');
        
        for (final video in gameVideos) {
          print('📝 ${video['title']} (${video['bvid']})');
          
          // 测试播放
          final bvid = video['bvid'];
          final detailResp = await http.get(
            Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ).timeout(Duration(seconds: 5));
          
          if (detailResp.statusCode == 200) {
            final detailData = jsonDecode(detailResp.body);
            if (detailData['code'] == 0) {
              final cid = detailData['data']['cid'];
              
              final playResp = await http.get(
                Uri.parse('https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid'),
                headers: {'User-Agent': 'Mozilla/5.0'},
              ).timeout(Duration(seconds: 5));
              
              if (playResp.statusCode == 200) {
                final playData = jsonDecode(playResp.body);
                if (playData['code'] == 0) {
                  print('   ✅ 播放功能正常!');
                } else {
                  print('   ❌ 播放失败: ${playData['message']}');
                }
              }
            }
          }
        }
        
        print('\n🎉 搜索和播放测试完成!');
      }
    }
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}