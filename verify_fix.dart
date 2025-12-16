import 'dart:convert';
import 'package:bili_ownx/api/video_api.dart';

void main() async {
  print('验证API修复是否有效...\n');
  
  // 使用已知可以工作的视频ID
  final workingBvid = 'BV1xx411c7mD';
  print('测试视频: $workingBvid');
  
  try {
    print('正在获取视频详情...');
    final videoDetail = await VideoApi.getVideoDetail(bvid: workingBvid);
    
    if (videoDetail['code'] == 0) {
      print('✅ 视频详情获取成功!');
      print('   - 标题: ${videoDetail['data']['title']}');
      print('   - 作者: ${videoDetail['data']['owner']['name']}');
      print('   - 时长: ${videoDetail['data']['duration']}秒');
      
      final cid = videoDetail['data']['cid'];
      print('   - CID: $cid');
      
      print('\n正在获取播放URL...');
      final playUrl = await VideoApi.getPlayUrl(bvid: workingBvid, cid: cid);
      
      if (playUrl['code'] == 0) {
        print('✅ 播放URL获取成功!');
        final playData = playUrl['data'];
        
        if (playData['durl'] != null) {
          print('   - 格式: MP4/FLV');
          print('   - 文件大小: ${(playData['durl'][0]['size'] / 1024 / 1024).toStringAsFixed(2)} MB');
          print('   - URL长度: ${playData['durl'][0]['url'].length} 字符');
        } else if (playData['dash'] != null) {
          print('   - 格式: DASH');
          print('   - 视频流数量: ${playData['dash']['video'].length}');
        }
        
        print('\n🎉 所有API调用都成功了! 修复有效!');
        
      } else {
        print('❌ 播放URL获取失败: ${playUrl['message']}');
      }
    } else {
      print('❌ 视频详情获取失败: ${videoDetail['message']}');
    }
    
  } catch (e) {
    print('❌ 发生异常: $e');
    print('   如果看到这个错误，说明API仍有问题');
  }
}