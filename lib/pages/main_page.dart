import 'package:flutter/material.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'download_list_page.dart';
import 'metadata_page.dart';

/// 主页面 - 包含底部导航栏
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const SearchPage(),
    const DownloadListPage(),
    const MetadataPage(),
    const SettingsPage(),
  ];

  // 底部导航项
  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.search),
      activeIcon: Icon(Icons.search),
      label: '搜索',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.download),
      activeIcon: Icon(Icons.download),
      label: '下载',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.folder),
      activeIcon: Icon(Icons.folder),
      label: '元数据',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      activeIcon: Icon(Icons.settings),
      label: '设置',
    ),
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
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}