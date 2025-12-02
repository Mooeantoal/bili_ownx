/// 测试 PlayerPage 构造函数修复
import 'lib/pages/player_page.dart';

void main() {
  print('测试 PlayerPage 构造函数修复...');
  
  try {
    // 测试1: 只有 bvid
    final player1 = PlayerPage(bvid: 'BV1234567890');
    print('✅ 测试1通过: 只有 bvid');
    
    // 测试2: 只有 aid
    final player2 = PlayerPage(bvid: '', aid: 12345678);
    print('✅ 测试2通过: 只有 aid');
    
    // 测试3: 使用工厂构造函数 - 只有 bvid
    final player3 = PlayerPage.withIds(bvid: 'BV0987654321');
    print('✅ 测试3通过: 工厂构造函数 - 只有 bvid');
    
    // 测试4: 使用工厂构造函数 - 只有 aid
    final player4 = PlayerPage.withIds(aid: 87654321);
    print('✅ 测试4通过: 工厂构造函数 - 只有 aid');
    
    // 测试5: 使用工厂构造函数 - 两者都有
    final player5 = PlayerPage.withIds(bvid: 'BV1111111111', aid: 11111111);
    print('✅ 测试5通过: 工厂构造函数 - 两者都有');
    
    print('\n🎉 所有测试通过！PlayerPage 构造函数修复成功。');
    
  } catch (e) {
    print('❌ 测试失败: $e');
  }
  
  // 测试断言错误
  try {
    final playerError = PlayerPage.withIds(); // 应该抛出断言错误
    print('❌ 断言测试失败: 应该抛出错误但没有');
  } catch (e) {
    print('✅ 断言测试通过: 正确抛出错误 - $e');
  }
}