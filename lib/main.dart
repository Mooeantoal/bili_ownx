import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/splash_page.dart';
import 'services/download_manager.dart';
import 'services/metadata_service.dart';
import 'services/theme_service.dart';
import 'services/network_service.dart';
import 'services/startup_service.dart';
import 'models/download_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 创建启动优化服务
  final startupService = StartupService();
  
  // 注册所有初始化任务（并行执行）
  startupService.registerInitializer(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DownloadTaskAdapter());
    }
  });
  
  startupService.registerInitializer(() => DownloadManager().initialize());
  startupService.registerInitializer(() => MetadataService().initialize());
  startupService.registerInitializer(() => ThemeService().initialize());
  startupService.registerInitializer(() => NetworkService().initialize());
  
  // 快速初始化基础服务（并行）
  await Future.wait([
    startupService.initialize(),
  ]);
  
  // 开始预热常用数据（不阻塞启动）
  startupService.warmup();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: NetworkService()),
            ChangeNotifierProvider.value(value: ThemeService()),
          ],
          child: MaterialApp(
            title: 'Bilibili Flutter',
            theme: ThemeService().lightTheme,
            darkTheme: ThemeService().darkTheme,
            themeMode: ThemeService().themeMode,
            debugShowCheckedModeBanner: false, // 移除debug横幅
            home: const SplashPage(), // 使用启动页面
          ),
        );
      },
    );
  }
}
