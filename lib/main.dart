import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/search_page.dart';
import 'services/download_manager.dart';
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilibili Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}
