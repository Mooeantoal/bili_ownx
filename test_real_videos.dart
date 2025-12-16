import 'dart:convert';
import 'package:bili_ownx/api/video_api.dart';

void main() async {
  print('🎬 测试真实B站视频...\n');
  
  // 这些是一些真实存在的B站视频ID（经过验证的）
  final realVideos = [
    {
      'bvid': 'BV1xx411c7mD',
      'name': '字幕君交流场所',
      'expected': true,
    },
    {
      'bvid': 'BV1GJ411x7h7', 
      'name': '经典测试视频',
      'expected': false, // 这个可能不可用
    },
    {
      'bvid': 'BV1uJ411C7cs',
      'name': '另一个测试视频',
      'expected': false, // 这个可能不可用
    },
  ];
  
  int successCount = 0;
  int failCount = 0;
  
  for (int i = 0; i < realVideos.length; i++) {
    final video = realVideos[i];
    final bvid = video['bvid'] as String;
    final name = video['name'] as String;
    final expected = video['expected'] as bool;
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📹 测试 ${i + 1}/3: $name');
    print('🔗 BVID: $bvid');
    print('🎯 预期: ${expected ? "应该成功" : "可能失败"}');
    print('');
    
    try {
      print('⏳ 正在获取视频详情...');
      final response = await VideoApi.getVideoDetail(bvid: bvid);
      
      if (response['code'] == 0 && response['data'] != null) {
        final data = response['data'];
        successCount++;
        
        print('✅ 视频详情获取成功!');
        print('   📝 标题: ${data['title']}');
        print('   👤 作者: ${data['owner']['name']}');
        print('   ⏱️  时长: ${data['duration']}秒 (${(data['duration'] / 60).toStringAsFixed(1)}分钟)');
        print('   🎬 CID: ${data['cid']}');
        print('   👀 播放量: ${data['stat']['view']}');
        print('   💬 弹幕: ${data['stat']['danmaku']}');
        
        // 尝试获取播放URL
        try {
          print('\n⏳ 正在获取播放URL...');
          final playUrl = await VideoApi.getPlayUrl(
            bvid: bvid,
            cid: data['cid'],
            qn: 80, // 高清
            fnval: 1, // MP4格式
          );
          
          if (playUrl['code'] == 0 && playUrl['data'] != null) {
            final playData = playUrl['data'];
            
            print('✅ 播放URL获取成功!');
            
            if (playData['durl'] != null) {
              final durl = playData['durl'][0];
              print('   🎞️  格式: MP4/FLV');
              print('   📦 大小: ${(durl['size'] / 1024 / 1024).toStringAsFixed(2)} MB');
              print('   🔗 URL长度: ${durl['url'].length} 字符');
              print('   ⚡ 清晰度: ${playData['quality'] ?? '未知'}');
              
              if (playData['accept_quality'] != null) {
                print('   📺 可用画质: ${playData['accept_quality']}');
              }
            } else if (playData['dash'] != null) {
              print('   🎞️  格式: DASH');
              final videos = playData['dash']['video'] as List?;
              if (videos != null) {
                print('   📺 可用视频流: ${videos.length} 个');
                for (int j = 0; j < videos.length && j < 3; j++) {
                  final video = videos[j];
                  print('      - ${video['id']}: ${video['codecs']} (${(video['bandwidth'] / 1000).toStringAsFixed(0)}kbps)');
                }
              }
            }
            
            print('🎉 这个视频完全可以播放!');
            
          } else {
            print('❌ 播放URL获取失败: ${playUrl['message']}');
            failCount++;
          }
          
        } catch (e) {
          print('❌ 获取播放URL时发生异常: $e');
          failCount++;
        }
        
      } else {
        failCount++;
        print('❌ 视频不存在或不可访问');
        print('   错误码: ${response['code']}');
        print('   错误信息: ${response['message']}');
        
        if (!expected) {
          print('   ℹ️  这是预期的结果');
        }
      }
      
    } catch (e) {
      failCount++;
      print('❌ 发生异常: $e');
      print('   📝 这可能是网络问题或API错误');
    }
    
    print('');
    
    // 避免请求过于频繁
    if (i < realVideos.length - 1) {
      print('⏳ 等待2秒后继续下一个测试...\n');
      await Future.delayed(Duration(seconds: 2));
    }
  }
  
  // 总结报告
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 测试总结');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ 成功: $successCount 个视频');
  print('❌ 失败: $failCount 个视频');
  print('📈 成功率: ${((successCount / realVideos.length) * 100).toStringAsFixed(1)}%');
  print('');
  
  if (successCount > 0) {
    print('🎉 恭喜! API修复成功，可以正常加载和播放视频!');
    print('💡 建议: 使用成功的视频ID在应用中进行完整测试');
  } else {
    print('⚠️  所有测试都失败了，可能需要检查网络连接或API访问权限');
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}