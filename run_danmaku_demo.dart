import 'package:flutter/material.dart';
import 'lib/pages/danmaku_demo_page.dart';

void main() {
  runApp(const DanmakuDemoApp());
}

class DanmakuDemoApp extends StatelessWidget {
  const DanmakuDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '弹幕系统演示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const DanmakuDemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}