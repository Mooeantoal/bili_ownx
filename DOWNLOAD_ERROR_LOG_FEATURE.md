# 下载错误日志弹窗功能

## 功能概述

为下载功能添加了详细的错误日志弹窗，当下载出现问题时，用户可以查看完整的错误日志并复制到剪贴板进行问题排查。

## 实现的功能

### 1. 错误日志收集
- **详细记录**: 记录下载过程中的所有关键信息
- **结构化日志**: 包含任务信息、API响应、下载进度等
- **异常捕获**: 捕获并记录所有异常和堆栈跟踪

### 2. 错误日志存储
- **数据模型扩展**: 在 `DownloadTask` 中添加 `errorLog` 字段
- **持久化存储**: 通过 Hive 数据库保存错误日志
- **JSON 序列化**: 支持错误日志的序列化和反序列化

### 3. 用户界面
- **错误指示器**: 在失败任务旁显示错误日志图标
- **弹窗显示**: 点击图标显示详细错误日志
- **一键复制**: 支持将日志复制到剪贴板

## 技术实现

### 1. 数据模型更新

```dart
class DownloadTask {
  String? errorLog;     // 详细错误日志
  
  // 在 copyWith、toJson、fromJson 中都添加了对应字段
}
```

### 2. 下载管理器增强

```dart
Future<void> _downloadTask(DownloadTask task) async {
  final errorLog = StringBuffer();
  
  try {
    // 记录任务开始信息
    errorLog.writeln('=== 下载任务开始 ===');
    errorLog.writeln('任务ID: ${task.id}');
    errorLog.writeln('视频标题: ${task.title}');
    // ... 更多日志记录
    
  } catch (e, stackTrace) {
    // 记录详细的错误信息
    errorLog.writeln('=== 下载失败 ===');
    errorLog.writeln('错误类型: ${e.runtimeType}');
    errorLog.writeln('错误信息: $e');
    errorLog.writeln('堆栈跟踪:');
    errorLog.writeln(stackTrace.toString());
    
    await _updateTaskStatus(
      task, 
      DownloadStatus.failed, 
      errorMessage: e.toString(),
      errorLog: errorLog.toString(),
    );
  }
}
```

### 3. 用户界面更新

```dart
// 在错误信息旁显示日志查看按钮
if (task.errorLog != null)
  IconButton(
    icon: const Icon(Icons.bug_report, size: 16),
    onPressed: () => _showErrorLogDialog(task),
    tooltip: '查看错误日志',
    color: Colors.red,
  ),

// 错误日志弹窗
void _showErrorLogDialog(DownloadTask task) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text('错误日志 - ${task.title}')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // 复制按钮
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: task.errorLog ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日志已复制到剪贴板')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制日志'),
            ),
            // 日志内容显示区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    task.errorLog ?? '暂无日志',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

## 日志内容示例

```
=== 下载任务开始 ===
任务ID: BV1234567890_123456789
视频标题: 测试视频标题
BVID: BV1234567890
CID: 123456789
画质: 高清 1080P (80)
开始时间: 2025-12-03T10:30:00.000Z

正在获取播放地址...
API响应: {code: -101, message: 账号未登录}

=== 下载失败 ===
错误类型: Exception
错误信息: 获取播放地址失败: 账号未登录
失败时间: 2025-12-03T10:30:01.000Z
```

## 用户体验

1. **直观显示**: 下载失败时，在错误信息旁显示红色错误日志图标
2. **便捷查看**: 点击图标弹出详细的错误日志窗口
3. **易于分享**: 一键复制日志到剪贴板，方便用户反馈问题
4. **美观界面**: 使用等宽字体显示日志，便于阅读技术信息

## 技术优势

- **完整记录**: 捕获下载过程中的所有关键信息
- **结构清晰**: 使用格式化的日志结构，便于问题定位
- **用户友好**: 提供直观的界面和便捷的操作
- **数据持久**: 错误日志保存在本地数据库中，应用重启后仍可查看

## 使用场景

1. **网络问题**: 记录网络请求详情和响应状态
2. **API 错误**: 记录 API 调用参数和返回结果
3. **文件系统错误**: 记录文件路径和权限问题
4. **用户反馈**: 用户可以将日志复制给开发者进行问题排查

这个功能大大提升了下载系统的可调试性和用户体验，让用户在遇到下载问题时能够获得足够的信息来理解和解决问题。