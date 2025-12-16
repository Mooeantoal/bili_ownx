import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('调试Bilibili API响应...\n');
  
  final testVideos = [
    'BV1uJ411C7cs',  // 这个通常存在
    'BV1GJ411x7h7',  // 测试另一个
    'BV1fs4y1W7SJ',  // 原始测试视频
  ];
  
  for (final testBvid in testVideos) {
    final url = 'https://api.bilibili.com/x/web-interface/view?bvid=$testBvid';
    
    print('\n--- 测试视频: $testBvid ---');
    print('请求URL: $url');
    print('正在发送请求...\n');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.bilibili.com',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        },
      ).timeout(Duration(seconds: 15));
      
      print('响应状态码: ${response.statusCode}');
      print('响应长度: ${response.body.length} 字节');
      print('响应内容:');
      print(response.body);
      
      // 检查是否为JSON
      try {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map) {
          if (jsonData.containsKey('code')) {
            if (jsonData['code'] == 0) {
              print('✅ 视频存在且可访问!');
              if (jsonData['data'] != null) {
                final data = jsonData['data'];
                print('   - 标题: ${data['title']}');
                print('   - 作者: ${data['owner']?['name']}');
                print('   - 时长: ${data['duration']}秒');
              }
            } else {
              print('❌ API返回错误: ${jsonData['code']} - ${jsonData['message']}');
            }
          }
        }
      } catch (e) {
        print('❌ JSON解析失败: $e');
      }
      
    } catch (e) {
      print('❌ 请求失败: $e');
    }
  }
}