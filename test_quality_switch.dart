import 'dart:convert';
import 'package:dio/dio.dart';

/// 测试画质切换功能
void main() async {
  final dio = Dio();
  
  // 测试视频的 BVID 和 CID
  const testBvid = 'BV1xx411c7mD'; // 一个常见的测试视频
  const testCid = 19772637; // 对应的 CID
  
  // 测试不同画质
  final qualities = [
    {'qn': 16, 'name': '流畅'},
    {'qn': 32, 'name': '清晰'},
    {'qn': 64, 'name': '高清'},
    {'qn': 80, 'name': '超清'},
    {'qn': 112, 'name': '高清 1080P'},
    {'qn': 116, 'name': '高清 1080P60'},
  ];
  
  print('=== 测试画质切换功能 ===\n');
  
  for (var quality in qualities) {
    final qn = quality['qn'];
    final name = quality['name'];
    
    print('测试画质: $name ($qn)');
    
    try {
      final response = await dio.get(
        'https://api.bilibili.com/x/player/playurl',
        queryParameters: {
          'bvid': testBvid,
          'cid': testCid,
          'qn': qn,
          'fnval': 1, // 使用 mp4 格式，更容易看到画质差异
          'fourk': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Referer': 'https://www.bilibili.com',
          },
        ),
      );
      
      final data = response.data;
      
      if (data['code'] == 0) {
        final playData = data['data'];
        
        if (playData['durl'] != null) {
          final durl = playData['durl'][0];
          final url = durl['url'];
          final size = durl['size'];
          
          print('  ✓ 成功获取播放地址');
          print('  - 文件大小: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
          print('  - URL 长度: ${url.length} 字符');
          
          // 从 URL 中提取画质信息
          if (url.contains('qn=')) {
            final urlQn = RegExp(r'qn=(\d+)').firstMatch(url)?.group(1);
            print('  - URL 中的画质参数: qn=$urlQn');
          }
          
          // 检查是否有其他画质相关参数
          if (url.contains('height=')) {
            final height = RegExp(r'height=(\d+)').firstMatch(url)?.group(1);
            print('  - 视频高度: height=$height');
          }
          
          if (url.contains('width=')) {
            final width = RegExp(r'width=(\d+)').firstMatch(url)?.group(1);
            print('  - 视频宽度: width=$width');
          }
          
        } else if (playData['dash'] != null) {
          print('  ✓ 返回 DASH 格式');
          final dash = playData['dash'];
          
          if (dash['video'] != null) {
            final videos = dash['video'] as List;
            print('  - 可用视频流数量: ${videos.length}');
            
            for (var video in videos.take(3)) { // 只显示前3个
              final id = video['id'];
              final width = video['width'];
              final height = video['height'];
              final codecid = video['codecid'];
              print('    * 流ID: $id, ${width}x$height, 编码: $codecid');
            }
          }
        } else {
          print('  ⚠ 未找到播放数据');
        }
        
        // 检查质量描述
        if (playData['quality'] != null) {
          print('  - API 返回的质量: ${playData['quality']}');
        }
        
        if (playData['accept_quality'] != null) {
          final acceptQuality = playData['accept_quality'] as List;
          print('  - 支持的画质: $acceptQuality');
        }
        
      } else {
        print('  ✗ API 返回错误: ${data['message']}');
      }
      
    } catch (e) {
      print('  ✗ 请求失败: $e');
    }
    
    print(''); // 空行分隔
  }
  
  print('=== 测试完成 ===');
}