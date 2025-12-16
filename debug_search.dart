import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 调试B站搜索API');
  print('==================');
  
  final keyword = '七实 芒星之迹';
  
  // 尝试简化的搜索端点
  final simpleUrl = 'https://api.bilibili.com/x/web-interface/search/all/v2?keyword=$keyword';
  
  print('🌐 测试简化搜索: $simpleUrl');
  
  try {
    final response = await http.get(
      Uri.parse(simpleUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.bilibili.com/',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    print('📊 状态码: ${response.statusCode}');
    print('📏 响应长度: ${response.body.length}');
    print('📄 响应内容: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print('✅ JSON解析成功');
        print('📋 数据结构: ${data.runtimeType}');
        
        if (data is Map) {
          print('🔑 包含键: ${data.keys.toList()}');
          
          if (data.containsKey('code')) {
            print('🔢 响应码: ${data['code']}');
            print('💬 消息: ${data['message']}');
            
            if (data['code'] == 0 && data['data'] != null) {
              print('✅ 搜索成功!');
              analyzeSearchData(data['data']);
            } else {
              print('❌ 搜索失败');
            }
          }
        }
      } catch (e) {
        print('❌ JSON解析失败: $e');
      }
    } else {
      print('❌ HTTP失败: ${response.statusCode}');
      print('📄 响应: ${response.body}');
    }
  } catch (e) {
    print('❌ 请求异常: $e');
  }
  
  // 尝试其他端点
  print('\n' + '='*50);
  print('🔍 测试备用搜索端点');
  
  final endpoints = [
    'https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=$keyword',
    'https://s.search.bilibili.com/main/hotword',  // 热门搜索
    'https://api.bilibili.com/x/web-interface/popular',  // 热门视频
  ];
  
  for (int i = 0; i < endpoints.length; i++) {
    final url = endpoints[i];
    print('\n📍 测试端点 ${i + 1}: $url');
    
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.bilibili.com/',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 8));
      
      print('   📊 状态: ${resp.statusCode}');
      print('   📏 长度: ${resp.body.length}');
      
      if (resp.statusCode == 200) {
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data.containsKey('code') && data['code'] == 0) {
            print('   ✅ 成功!');
            if (data['data'] != null) {
              final responseData = data['data'];
              if (responseData is List) {
                print('   📺 找到 ${responseData.length} 个项目');
              } else if (responseData is Map) {
                print('   📋 数据字段: ${responseData.keys.toList()}');
              }
            }
          } else {
            print('   ⚠️  API返回非成功状态');
          }
        } catch (e) {
          print('   ⚠️  JSON解析失败: $e');
        }
      } else {
        print('   ❌ HTTP失败');
      }
    } catch (e) {
      print('   ❌ 请求失败: $e');
    }
  }
}

void analyzeSearchData(dynamic data) {
  print('🔍 分析搜索数据...');
  
  if (data is Map) {
    print('📋 数据字段: ${data.keys.toList()}');
    
    // 查找包含视频的字段
    final videoFields = ['result', 'data', 'items', 'list', 'vlist', 'video', 'videos'];
    
    for (final field in videoFields) {
      if (data.containsKey(field)) {
        print('🎬 找到视频字段: $field');
        final fieldData = data[field];
        
        if (fieldData is List) {
          print('   📹 列表长度: ${fieldData.length}');
          if (fieldData.isNotEmpty) {
            final firstItem = fieldData.first;
            if (firstItem is Map) {
              print('   🔑 首项字段: ${firstItem.keys.toList()}');
              
              // 尝试提取关键信息
              final title = firstItem['title'] ?? firstItem['name'] ?? '无标题';
              final author = firstItem['author'] ?? firstItem['uname'] ?? '未知';
              final bvid = firstItem['bvid'] ?? firstItem['bvid'] ?? '无BVID';
              
              print('   📝 示例: $title - $author ($bvid)');
            }
          }
        } else if (fieldData is Map) {
          print('   📋 嵌套字段: ${fieldData.keys.toList()}');
        }
      }
    }
  } else if (data is List) {
    print('📹 数据是列表，长度: ${data.length}');
    if (data.isNotEmpty) {
      final firstItem = data.first;
      if (firstItem is Map) {
        print('   🔑 首项字段: ${firstItem.keys.toList()}');
      }
    }
  }
}