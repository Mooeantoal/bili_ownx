import 'package:bili_ownx/api/search_api.dart';
import 'package:bili_ownx/models/search_result.dart';
import 'package:bili_ownx/api/video_api.dart';

/// 完整测试：搜索→解析→播放
void main() async {
  print('=== 完整搜索播放测试 ===');
  
  try {
    // 1. 搜索视频
    print('1. 搜索"战双帕弥什"...');
    final searchResult = await SearchApi.searchArchive(keyword: '战双帕弥什');
    
    if (searchResult['code'] != 0) {
      throw Exception('搜索失败: ${searchResult['message']}');
    }
    
    // 2. 解析结果
    print('2. 解析搜索结果...');
    final data = searchResult['data'];
    List<dynamic> videoList = data['result'] ?? data['items'] ?? [];
    
    if (videoList.isEmpty) {
      throw Exception('没有找到视频');
    }
    
    print('找到 ${videoList.length} 个视频');
    
    // 3. 测试第一个视频
    final videoJson = videoList.first;
    final video = VideoSearchResult.fromJson(videoJson);
    
    print('3. 视频信息:');
    print('   标题: ${video.title}');
    print('   BVID: "${video.bvid}"');
    print('   AID: ${video.aid}');
    print('   有效ID: ${video.hasValidId}');
    
    if (!video.hasValidId) {
      throw Exception('视频ID无效');
    }
    
    // 4. 获取视频详情（关键测试）
    print('4. 获取视频详情...');
    final videoDetail = await VideoApi.getVideoDetail(
      bvid: video.bvid.isNotEmpty ? video.bvid : null,
      aid: video.aid != 0 ? video.aid : null,
    );
    
    if (videoDetail['code'] == 0) {
      final videoData = videoDetail['data'];
      print('✅ 视频详情获取成功！');
      print('   完整标题: ${videoData['title']}');
      print('   UP主: ${videoData['owner']['name']}');
      print('   播放量: ${videoData['stat']['view']}');
      print('   时长: ${videoData['duration']}');
    } else {
      throw Exception('获取视频详情失败: ${videoDetail['message']}');
    }
    
  } catch (e) {
    print('❌ 测试失败: $e');
  }
  
  print('\n=== 测试完成 ===');
}