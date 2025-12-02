/// 测试 BVID 空字符串修复
import 'lib/api/video_api.dart';

void main() async {
  print('测试 BVID 空字符串修复...');
  
  try {
    // 测试1: 空字符串 BVID 应该抛出错误
    print('测试1: 空字符串 BVID');
    try {
      await VideoApi.getPlayUrl(bvid: '', cid: 12345678);
      print('❌ 测试1失败: 应该抛出 ArgumentError');
    } catch (e) {
      if (e is ArgumentError && e.message.contains('BVID 不能为空')) {
        print('✅ 测试1通过: 正确抛出 ArgumentError');
      } else {
        print('❌ 测试1失败: 抛出了错误的异常类型 - $e');
      }
    }
    
    // 测试2: 无效 CID 应该抛出错误
    print('\n测试2: 无效 CID');
    try {
      await VideoApi.getPlayUrl(bvid: 'BV1234567890', cid: 0);
      print('❌ 测试2失败: 应该抛出 ArgumentError');
    } catch (e) {
      if (e is ArgumentError && e.message.contains('CID 必须大于 0')) {
        print('✅ 测试2通过: 正确抛出 ArgumentError');
      } else {
        print('❌ 测试2失败: 抛出了错误的异常类型 - $e');
      }
    }
    
    // 测试3: 负数 CID 应该抛出错误
    print('\n测试3: 负数 CID');
    try {
      await VideoApi.getPlayUrl(bvid: 'BV1234567890', cid: -1);
      print('❌ 测试3失败: 应该抛出 ArgumentError');
    } catch (e) {
      if (e is ArgumentError && e.message.contains('CID 必须大于 0')) {
        print('✅ 测试3通过: 正确抛出 ArgumentError');
      } else {
        print('❌ 测试3失败: 抛出了错误的异常类型 - $e');
      }
    }
    
    print('\n🎉 BVID 验证测试完成！');
    
  } catch (e) {
    print('❌ 测试过程中发生意外错误: $e');
  }
}