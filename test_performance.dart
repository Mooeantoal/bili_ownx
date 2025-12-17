import 'lib/services/startup_service.dart';
import 'lib/services/performance_service.dart';
import 'lib/services/network_service.dart';
import 'lib/services/theme_service.dart';

/// 性能测试脚本
void main() async {
  print('🚀 开始性能测试...');
  
  final performanceService = PerformanceService();
  
  // 测试启动服务
  print('\n📊 测试1: 启动服务性能');
  performanceService.startTimer('startup_test');
  
  final startupService = StartupService();
  
  // 模拟注册服务
  startupService.registerInitializer(() async {
    await Future.delayed(Duration(milliseconds: 100));
    print('✅ 模拟服务1初始化完成');
  });
  
  startupService.registerInitializer(() async {
    await Future.delayed(Duration(milliseconds: 150));
    print('✅ 模拟服务2初始化完成');
  });
  
  startupService.registerInitializer(() async {
    await Future.delayed(Duration(milliseconds: 80));
    print('✅ 模拟服务3初始化完成');
  });
  
  await startupService.initialize();
  
  final startupTime = performanceService.endTimer('startup_test');
  print('⏱️ 启动服务总耗时: ${startupTime}ms');
  
  // 测试网络预热
  print('\n🌐 测试2: 网络预热性能');
  performanceService.startTimer('network_warmup');
  
  final networkService = NetworkService();
  await networkService.warmupCache();
  
  final networkTime = performanceService.endTimer('network_warmup');
  print('⏱️ 网络预热耗时: ${networkTime}ms');
  
  // 测试主题预热
  print('\n🎨 测试3: 主题预热性能');
  performanceService.startTimer('theme_warmup');
  
  final themeService = ThemeService();
  await themeService.warmup();
  
  final themeTime = performanceService.endTimer('theme_warmup');
  print('⏱️ 主题预热耗时: ${themeTime}ms');
  
  // 打印完整报告
  print('\n📈 完整性能报告:');
  performanceService.printPerformanceReport();
  
  print('\n✅ 性能测试完成!');
  print('💡 提示: 在Release模式下运行可获得更好的性能表现');
}