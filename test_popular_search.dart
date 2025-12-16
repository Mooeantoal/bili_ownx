import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 使用热门API搜索相关内容');
  print('============================');
  
  final keyword = '七实 芒星之迹';
  print('🎯 目标关键词: $keyword');
  print('');
  
  // 1. 先获取热门视频
  print('1️⃣ 获取热门视频列表...');
  try {
    final popularResponse = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/popular'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.bilibili.com/',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    if (popularResponse.statusCode == 200) {
      final popularData = jsonDecode(popularResponse.body);
      
      if (popularData['code'] == 0 && popularData['data'] != null) {
        final videos = popularData['data']['list'] as List;
        print('✅ 获取到 ${videos.length} 个热门视频');
        
        print('\n2️⃣ 搜索包含关键词的相关视频...');
        
        List<Map<String, dynamic>> relatedVideos = [];
        
        // 检查每个热门视频是否包含相关关键词
        for (int i = 0; i < videos.length && i < 10; i++) {
          final video = videos[i] as Map;
          final title = (video['title'] ?? '').toString().toLowerCase();
          final desc = (video['desc'] ?? '').toString().toLowerCase();
          final author = (video['owner']['name'] ?? '').toString().toLowerCase();
          
          // 检查是否包含相关关键词
          final keywords = ['七实', '芒星', '战双', '帕弥什', '库洛', '游戏'];
          bool isRelated = false;
          String foundKeyword = '';
          
          for (final kw in keywords) {
            if (title.contains(kw) || desc.contains(kw) || author.contains(kw)) {
              isRelated = true;
              foundKeyword = kw;
              break;
            }
          }
          
          if (isRelated) {
            relatedVideos.add(Map<String, dynamic>.from(video));
            print('🎬 找到相关视频 ${i + 1}:');
            print('   📝 标题: ${video['title']}');
            print('   👤 作者: ${video['owner']['name']}');
            print('   🔍 匹配关键词: $foundKeyword');
            print('   🆔 BVID: ${video['bvid']}');
            print('   👀 播放量: ${video['stat']['view']}');
            
            // 测试播放功能
            await testVideoPlayback(video['bvid'], video['title']);
            print('');
          }
        }
        
        if (relatedVideos.isEmpty) {
          print('⚠️  在热门视频中未找到"七实 芒星之迹"相关内容');
          
          // 显示一些热门视频作为替代测试
          print('\n💡 作为替代，测试几个热门视频的播放功能:');
          for (int i = 0; i < 3 && i < videos.length; i++) {
            final video = videos[i];
            print('\n🔥 热门视频 ${i + 1}:');
            print('   📝 标题: ${video['title']}');
            print('   👤 作者: ${video['owner']['name']}');
            print('   🆔 BVID: ${video['bvid']}');
            
            await testVideoPlayback(video['bvid'], video['title']);
          }
        } else {
          print('\n🎉 总共找到 ${relatedVideos.length} 个相关视频!');
        }
        
      } else {
        print('❌ 热门API返回错误: ${popularData['message']}');
      }
    } else {
      print('❌ 热门API请求失败: ${popularResponse.statusCode}');
    }
  } catch (e) {
    print('❌ 获取热门视频失败: $e');
  }
  
  print('\n' + '='*50);
  print('3️⃣ 尝试直接搜索已知的相关视频ID...');
  
  // 尝试一些可能存在的相关视频ID
  final possibleVideos = [
    'BV1xx411c7mD', // 已知可工作
    'BV1GJ411x7h7', // 测试视频
    'BV1uJ411C7cs', // 另一个测试
  ];
  
  for (int i = 0; i < possibleVideos.length; i++) {
    final bvid = possibleVideos[i];
    print('\n🔍 测试视频 $bvid...');
    
    await testVideoDetails(bvid);
  }
  
  print('\n🏁 搜索测试完成!');
}

Future<void> testVideoPlayback(String bvid, String title) async {
  print('   🎬 测试播放: $title ($bvid)');
  
  try {
    final response = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.bilibili.com/',
      },
    ).timeout(Duration(seconds: 8));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0 && data['data'] != null) {
        final videoData = data['data'];
        final cid = videoData['cid'];
        final realTitle = videoData['title'];
        
        print('      ✅ 视频详情获取成功');
        print('      📹 实际标题: $realTitle');
        print('      🎬 CID: $cid');
        
        // 获取播放URL
        final playResponse = await http.get(
          Uri.parse('https://api.bilibili.com/x/player/playurl?bvid=$bvid&cid=$cid&qn=80&fnval=1'),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        ).timeout(Duration(seconds: 8));
        
        if (playResponse.statusCode == 200) {
          final playData = jsonDecode(playResponse.body);
          if (playData['code'] == 0) {
            print('      ✅ 播放URL获取成功');
            
            if (playData['data']['durl'] != null) {
              print('      🎞️  格式: MP4/FLV');
              print('      📦 大小: ${(playData['data']['durl'][0]['size'] / 1024 / 1024).toStringAsFixed(2)} MB');
            } else if (playData['data']['dash'] != null) {
              print('      🎞️  格式: DASH');
            }
            print('      🎉 视频可以正常播放!');
          } else {
            print('      ❌ 播放URL失败: ${playData['message']}');
          }
        } else {
          print('      ❌ 播放URL请求失败: ${playResponse.statusCode}');
        }
      } else {
        print('      ❌ 视频详情失败: ${data['message']}');
      }
    } else {
      print('      ❌ 视频详情请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print('      ❌ 播放测试异常: $e');
  }
}

Future<void> testVideoDetails(String bvid) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.bilibili.com/x/web-interface/view?bvid=$bvid'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.bilibili.com/',
      },
    ).timeout(Duration(seconds: 8));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0 && data['data'] != null) {
        final videoData = data['data'];
        print('   ✅ 视频存在: ${videoData['title']}');
        print('   👤 作者: ${videoData['owner']['name']}');
        print('   👀 播放量: ${videoData['stat']['view']}');
        
        // 检查是否与"七实 芒星之迹"相关
        final title = videoData['title'].toString().toLowerCase();
        if (title.contains('七实') || title.contains('芒星') || title.contains('战双') || title.contains('帕弥什')) {
          print('   🎯 🎉 这个视频与搜索主题相关!');
          
          // 测试播放
          await testVideoPlayback(bvid, videoData['title']);
        }
      } else {
        print('   ❌ 视频不存在: ${data['message']}');
      }
    } else {
      print('   ❌ 请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ 异常: $e');
  }
}