import 'package:flutter/material.dart';
import '../models/search_result.dart';

/// 测试数据解析页面
class TestParsingPage extends StatefulWidget {
  const TestParsingPage({super.key});

  @override
  State<TestParsingPage> createState() => _TestParsingPageState();
}

class _TestParsingPageState extends State<TestParsingPage> {
  final List<Map<String, dynamic>> _testData = [
    // 测试1: 标准数据
    {
      'title': '测试视频1',
      'cover': 'https://example.com/cover1.jpg',
      'author': 'UP主1',
      'play': 125000,
      'duration': '10:30',
      'bvid': 'BV1234567890',
      'aid': 987654321,
    },
    // 测试2: 时长为数字（可能的问题）
    {
      'title': '测试视频2',
      'cover': 'https://example.com/cover2.jpg',
      'author': 'UP主2',
      'play': 85000,
      'duration': 630, // 10分30秒，以秒数形式
      'bvid': 'BV0987654321',
      'aid': 123456789,
    },
    // 测试3: 缺少某些字段
    {
      'title': '测试视频3',
      'cover': '',
      'author': '',
      'play': null,
      'duration': null,
      'bvid': '',
      'aid': 0,
    },
    // 测试4: 类型混乱（可能导致错误）
    {
      'title': 12345, // 数字类型的标题
      'cover': null,
      'author': 67890, // 数字类型的作者
      'play': '15.5万', // 字符串类型的播放量
      'duration': [], // 数组类型的时长
      'bvid': null,
      'aid': '123456789', // 字符串类型的aid
    },
    // 测试5: 完整数据
    {
      'title': '完整数据测试',
      'cover': 'https://example.com/cover5.jpg',
      'author': '完整UP主',
      'play': 1000000,
      'duration': '25:00',
      'bvid': 'BV1122334455',
      'aid': 555444333,
      'danmaku': 5000,
      'like': 25000,
      'coin': 1200,
      'favorite': 8000,
      'reply': 1500,
      'pubdate': 1700000000,
      'description': '这是一个完整的视频描述',
      'mid': '888888888',
    },
  ];

  List<VideoSearchResult> _parsedResults = [];
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _testParsing();
  }

  void _testParsing() {
    _parsedResults.clear();
    _errors.clear();

    for (int i = 0; i < _testData.length; i++) {
      try {
        final result = VideoSearchResult.fromJson(_testData[i]);
        _parsedResults.add(result);
        print('✅ 测试 ${i + 1} 解析成功');
      } catch (e, stackTrace) {
        final error = '❌ 测试 ${i + 1} 解析失败: $e';
        _errors.add(error);
        print(error);
        print('堆栈跟踪: $stackTrace');
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据解析测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testParsing,
              child: const Text('重新测试'),
            ),
            const SizedBox(height: 16),
            
            // 错误信息
            if (_errors.isNotEmpty) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '解析错误',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._errors.map((error) => Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 成功解析的结果
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '成功解析 (${_parsedResults.length}/${_testData.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._parsedResults.asMap().entries.map((entry) {
                      final index = entry.key;
                      final result = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('视频 ${index + 1}', 
                                   style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('标题: ${result.title}'),
                              Text('UP主: ${result.author}'),
                              Text('播放量: ${result.play}'),
                              Text('时长: ${result.duration}'),
                              Text('BV号: ${result.bvid}'),
                              Text('AV号: ${result.aid}'),
                              if (result.danmaku > 0) Text('弹幕数: ${result.danmaku}'),
                              if (result.like > 0) Text('点赞数: ${result.like}'),
                              if (result.description.isNotEmpty) 
                                Text('描述: ${result.description}'),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}