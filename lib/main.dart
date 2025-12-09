import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/main_page.dart';
import 'services/download_manager.dart';
import 'services/metadata_service.dart';
import 'services/theme_service.dart';
import 'services/network_service.dart';
import 'models/download_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Hive
  await Hive.initFlutter();
  
  // 注册适配器
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(DownloadTaskAdapter());
  }
  
  // 初始化下载管理器
  await DownloadManager().initialize();
  
  // 初始化元数据服务
  await MetadataService().initialize();
  
  // 初始化主题服务
  await ThemeService().initialize();
  
  // 初始化网络服务
  await NetworkService().initialize();
  
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
            home: const MainPage(),
          ),
        );
      },
    );
  }
}
