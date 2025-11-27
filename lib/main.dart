import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'pages/search_page.dart';

void main() {
  // 初始化 media_kit (用于视频播放)
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
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
