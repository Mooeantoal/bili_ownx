import 'package:bili_ownx/api/api_helper.dart';
import 'package:bili_ownx/api/search_api.dart';

/// API 签名测试脚本
/// 运行方式: dart run test/api_test.dart
void main() async {
  print('=== Bilibili API 签名测试 ===\n');
  
  // 测试1: 检查签名生成
  print('测试1: 签名生成');
  final testParams = {
    'keyword': '测试',
    'pn': 1,
    'ps': 20,
  };
  
  final signedParams = ApiHelper.createParams(testParams);
  print('原始参数: $testParams');
  print('签名后参数: $signedParams');
  print('签名值: ${signedParams['sign']}');
  print('时间戳: ${signedParams['ts']}\n');
  
  // 测试2: 实际搜索请求
  print('测试2: 搜索请求');
  try {
    final result = await SearchApi.searchArchive(
      keyword: '鬼畜',
      pageNum: 1,
      pageSize: 5,
    );
    
    print('请求状态码: ${result['code']}');
    print('消息: ${result['message']}');
    
    if (result['code'] == 0) {
      print('✅ API 签名验证成功!');
      final items = result['data']?['items'];
      if (items != null && items is List) {
        print('搜索结果数量: ${items.length}');
        if (items.isNotEmpty) {
          print('第一个结果标题: ${items[0]['title']}');
        }
      }
    } else {
      print('❌ API 请求失败: ${result['message']}');
    }
  } catch (e) {
    print('❌ 请求异常: $e');
  }
  
  print('\n=== 测试完成 ===');
}
