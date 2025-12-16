import 'dart:io';
import 'dart:convert';
import 'package:bili_ownx/api/video_api.dart';

void main() async {
  print('开始测试视频API...\n');
  
  // 测试几个已知存在的视频ID
  final testVideos = [
    {'bvid': 'BV1xx411c7mD', 'aid': null, 'name': '字幕君交流场所 (可工作)'},
    {'bvid': 'BV1uJ411C7cs', 'aid': null, 'name': '测试视频2'},
    {'bvid': 'BV1GJ411x7h7', 'aid': null, 'name': '短视频测试'},
    {'bvid': 'BV1fs4y1W7SJ', 'aid': null, 'name': '原始失败视频'},
  ];
  
  for (int i = 0; i < testVideos.length; i++) {
    final video = testVideos[i];
    print('测试 ${i + 1}/${testVideos.length}: ${video['name']}');
    print('参数: BVID="${video['bvid']}", AID=${video['aid']}');
    
    try {
      final result = await VideoApi.getVideoDetail(
        bvid: video['bvid'] as String?,
        aid: video['aid'] as int?,
      );
      
      print('✅ 成功获取视频信息!');
      print('   - Code: ${result['code']}');
      print('   - Message: ${result['message']}');
      
      if (result['code'] == 0 && result['data'] != null) {
        final data = result['data'];
        print('   - 标题: ${data['title']}');
        print('   - 作者: ${data['owner']['name']}');
        print('   - 时长: ${data['duration']}秒');
        print('   - 观看: ${data['stat']['view']}次');
        
        // 如果有CID，尝试获取播放URL
        if (data['cid'] != null) {
          print('   - CID: ${data['cid']}');
          try {
            final playUrl = await VideoApi.getPlayUrl(
              bvid: video['bvid'] as String? ?? '',
              cid: data['cid'],
            );
            print('   ✅ 成功获取播放URL!');
            print('      - Code: ${playUrl['code']}');
            if (playUrl['code'] == 0 && playUrl['data'] != null) {
              final playData = playUrl['data'];
              if (playData['durl'] != null) {
                print('      - 格式: MP4/FLV');
                print('      - 时长: ${playData['length']}毫秒');
              } else if (playData['dash'] != null) {
                print('      - 格式: DASH');
              }
            }
          } catch (e) {
            print('   ❌ 获取播放URL失败: $e');
          }
        }
      } else {
        print('   ❌ API返回错误: ${result['message']}');
      }
      
    } catch (e) {
      print('❌ 获取视频信息失败: $e');
    }
    
    print('\n' + '='*60 + '\n');
    
    // 避免请求过快
    await Future.delayed(Duration(seconds: 2));
  }
  
  print('API测试完成!');
}