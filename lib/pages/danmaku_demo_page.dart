import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/danmaku.dart';
import '../services/danmaku_service.dart';
import '../widgets/danmaku_canvas.dart';
import '../widgets/danmaku_input.dart';
import '../widgets/danmaku_settings.dart';

/// 弹幕功能演示页面
class DanmakuDemoPage extends StatefulWidget {
  const DanmakuDemoPage({super.key});

  @override
  State<DanmakuDemoPage> createState() => _DanmakuDemoPageState();
}

class _DanmakuDemoPageState extends State<DanmakuDemoPage> {
  final DanmakuService _danmakuService = DanmakuService();
  bool _showDanmakuInput = false;
  bool _showDanmakuSettings = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _loadDemoDanmakus();
  }

  void _loadDemoDanmakus() {
    // 加载演示弹幕数据
    final demoDanmakus = [
      Danmaku.scroll('欢迎来到弹幕演示页面！', color: Colors.red, fontSize: 18),
      Danmaku.top('这是一条顶部弹幕', color: Colors.yellow, fontSize: 16),
      Danmaku.bottom('这是一条底部弹幕', color: Colors.green, fontSize: 16),
      Danmaku.scroll('Flutter弹幕系统演示', color: Colors.blue, fontSize: 20),
      Danmaku.scroll('支持多种颜色和字体大小', color: Colors.purple, fontSize: 14),
      Danmaku.top('🎉 庆祝弹幕功能上线！', color: Colors.orange, fontSize: 18),
      Danmaku.scroll('666666', color: Colors.cyan, fontSize: 16),
      Danmaku.scroll('这个弹幕系统太棒了！', color: Colors.pink, fontSize: 16),
      Danmaku.bottom('支持滚动、顶部、底部三种弹幕类型', color: Colors.lime, fontSize: 14),
      Danmaku.scroll('可以自定义颜色和字体大小', color: Colors.indigo, fontSize: 16),
      Danmaku.top('🚀 高性能弹幕渲染', color: Colors.teal, fontSize: 18),
      Danmaku.scroll('支持弹幕过滤和设置', color: Colors.amber, fontSize: 16),
      Danmaku.scroll('实时弹幕发送和接收', color: Colors.deepOrange, fontSize: 16),
      Danmaku.bottom('弹幕统计功能', color: Colors.brown, fontSize: 14),
      Danmaku.scroll('支持弹幕导出和导入', color: Colors.grey, fontSize: 16),
    ];

    for (final danmaku in demoDanmakus) {
      _danmakuService.addLocalDanmaku(danmaku);
    }
  }

  void _sendDanmaku(Danmaku danmaku) {
    _danmakuService.addLocalDanmaku(danmaku);
    setState(() {
      _showDanmakuInput = false;
    });
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _showDanmakuInputDialog() {
    setState(() {
      _showDanmakuInput = true;
    });
  }

  void _showDanmakuSettingsDialog() {
    setState(() {
      _showDanmakuSettings = true;
    });
  }

  void _clearDanmakus() {
    _danmakuService.clearDanmakus();
  }

  void _addRandomDanmaku() {
    final texts = [
      '随机弹幕内容',
      '这是一条随机弹幕',
      'Flutter太强了',
      '弹幕系统测试',
      '哈哈哈笑死我了',
      '前方高能预警',
      '泪目了',
      '爷青回',
      '一键三连',
      '关注UP主',
    ];
    
    final colors = [
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
    ];
    
    final types = DanmakuType.values;
    
    final randomText = texts[(DateTime.now().millisecondsSinceEpoch) % texts.length];
    final randomColor = colors[(DateTime.now().millisecondsSinceEpoch) % colors.length];
    final randomType = types[(DateTime.now().millisecondsSinceEpoch) % types.length];
    final randomFontSize = 14.0 + ((DateTime.now().millisecondsSinceEpoch) % 4) * 2.0;
    
    final danmaku = Danmaku(
      text: randomText,
      color: randomColor,
      fontSize: randomFontSize,
      type: randomType,
      time: DateTime.now(),
    );
    
    _danmakuService.addLocalDanmaku(danmaku);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _danmakuService,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('弹幕功能演示'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayback,
              tooltip: _isPlaying ? '暂停弹幕' : '播放弹幕',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _showDanmakuInputDialog,
              tooltip: '发送弹幕',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showDanmakuSettingsDialog,
              tooltip: '弹幕设置',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _clearDanmakus();
                    break;
                  case 'random':
                    _addRandomDanmaku();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear),
                    title: Text('清空弹幕'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'random',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('添加随机弹幕'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            // 背景内容
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade900,
                    Colors.purple.shade900,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.comment,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '弹幕系统演示',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '支持滚动、顶部、底部弹幕',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Consumer<DanmakuService>(
                      builder: (context, danmakuService, child) {
                        final stats = danmakuService.getStatistics();
                        return Card(
                          margin: const EdgeInsets.all(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '弹幕统计',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Text('总弹幕数: ${stats['totalCount']}'),
                                Text('滚动弹幕: ${stats['scrollCount']}'),
                                Text('顶部弹幕: ${stats['topCount']}'),
                                Text('底部弹幕: ${stats['bottomCount']}'),
                                Text('平均长度: ${stats['averageLength'].toStringAsFixed(1)}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // 弹幕画布
            Consumer<DanmakuService>(
              builder: (context, danmakuService, child) {
                return DanmakuCanvas(
                  danmakus: danmakuService.danmakus,
                  isPlaying: _isPlaying,
                  opacity: danmakuService.opacity,
                  fontSize: danmakuService.fontSize,
                  showScroll: danmakuService.showScroll,
                  showTop: danmakuService.showTop,
                  showBottom: danmakuService.showBottom,
                  onDanmakuTap: (danmaku) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('点击了弹幕: ${danmaku.text}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
            
            // 弹幕输入框
            if (_showDanmakuInput)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DanmakuInput(
                  onSend: _sendDanmaku,
                  enabled: true,
                ),
              ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "add_random",
              onPressed: _addRandomDanmaku,
              child: const Icon(Icons.add),
              tooltip: '添加随机弹幕',
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "clear_danmaku",
              onPressed: _clearDanmakus,
              child: const Icon(Icons.clear),
              tooltip: '清空弹幕',
            ),
          ],
        ),
      ),
    );
  }
}