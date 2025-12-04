import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/search_page.dart';
import 'pages/metadata_page.dart';
import 'pages/danmaku_demo_page.dart';
import 'services/download_manager.dart';
import 'services/metadata_service.dart';
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
      home: const MainPage(),
    );
  }
}

/// 主页面
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SearchPage(),
    const DanmakuDemoPage(),
    const MetadataPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment),
            label: '弹幕演示',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: '元数据',
          ),
        ],
      ),
    );
  }
}
