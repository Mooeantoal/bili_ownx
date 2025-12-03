import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/download_task.dart';
import '../services/download_manager.dart';
import '../services/download_manager.dart' as dm;

/// 下载列表页面
class DownloadListPage extends StatefulWidget {
  const DownloadListPage({super.key});

  @override
  State<DownloadListPage> createState() => _DownloadListPageState();
}

class _DownloadListPageState extends State<DownloadListPage> {
  List<DownloadTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 加载任务列表
  Future<void> _loadTasks() async {
    try {
      final manager = DownloadManager();
      final tasks = manager.getAllTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 开始自动刷新
  void _startAutoRefresh() {
    // 每秒刷新一次当前任务状态
    Stream.periodic(const Duration(seconds: 1), (_) => _loadTasks()).listen((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 清理已完成
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearCompleted,
            tooltip: '清理已完成',
          ),
          // 全部暂停
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: _pauseAll,
            tooltip: '全部暂停',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无下载任务',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '去搜索页面下载视频吧',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _DownloadTaskCard(
            task: task,
            onTaskAction: _handleTaskAction,
          );
        },
      ),
    );
  }

  /// 处理任务操作
  Future<void> _handleTaskAction(String taskId, String action) async {
    final manager = DownloadManager();
    
    try {
      switch (action) {
        case 'pause':
          await manager.pauseTask(taskId);
          break;
        case 'resume':
          await manager.resumeTask(taskId);
          break;
        case 'cancel':
          final confirmed = await _showConfirmDialog('确认取消', '确定要取消这个下载任务吗？');
          if (confirmed == true) {
            await manager.cancelTask(taskId);
          }
          break;
        case 'delete':
          final confirmed = await _showConfirmDialog('确认删除', '确定要删除这个下载任务吗？\n删除后无法恢复。');
          if (confirmed == true) {
            await manager.deleteTask(taskId);
          }
          break;
        case 'retry':
          await manager.resumeTask(taskId);
          break;
      }
      
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  /// 显示确认对话框
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误日志对话框
  void _showErrorLogDialog(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '错误日志 - ${task.title}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 复制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: task.errorLog ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('日志已复制到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制日志'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 日志内容
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 清理已完成任务
  Future<void> _clearCompleted() async {
    final manager = DownloadManager();
    await manager.clearCompletedTasks();
    await _loadTasks();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清理完成的任务')),
      );
    }
  }

  /// 暂停所有任务
  Future<void> _pauseAll() async {
    final manager = DownloadManager();
    final downloadingTasks = _tasks.where((t) => t.isDownloading).toList();
    
    for (final task in downloadingTasks) {
      await manager.pauseTask(task.id);
    }
    
    await _loadTasks();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已暂停 ${downloadingTasks.length} 个任务')),
      );
    }
  }
}

/// 下载任务卡片
class _DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final Function(String taskId, String action) onTaskAction;

  const _DownloadTaskCard({
    required this.task,
    required this.onTaskAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                // 缩略图
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    task.cover,
                    width: 60,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 标题和信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              task.qualityName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (task.author != null) ...[
                            Text(
                              task.author!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 进度条
            if (task.isDownloading || task.isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: task.progressPercent,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.isCompleted ? '100%' : '${(task.progressPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (task.speed > 0 && !task.isCompleted)
                    Text(
                      '${_formatSpeed(task.speed)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ] else ...[
              // 状态文本
              Text(
                task.statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusTextColor(task.status),
                ),
              ),
              if (task.errorMessage != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.errorLog != null)
                      IconButton(
                        icon: const Icon(Icons.bug_report, size: 16),
                        onPressed: () => _showErrorLogDialog(task),
                        tooltip: '查看错误日志',
                        color: Colors.red,
                      ),
                  ],
                ),
              ],
            ],
            
            const SizedBox(height: 12),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];
    
    if (task.isDownloading) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.pause, size: 20),
          onPressed: () => onTaskAction(task.id, 'pause'),
          tooltip: '暂停',
        ),
      );
    }
    
    if (task.canResume) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 20),
          onPressed: () => onTaskAction(task.id, 'resume'),
          tooltip: '恢复',
        ),
      );
    }
    
    if (task.status == DownloadStatus.failed) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => onTaskAction(task.id, 'retry'),
          tooltip: '重试',
        ),
      );
    }
    
    if (task.canCancel) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.cancel, size: 20),
          onPressed: () => onTaskAction(task.id, 'cancel'),
          tooltip: '取消',
        ),
      );
    }
    
    buttons.add(
      IconButton(
        icon: const Icon(Icons.delete, size: 20),
        onPressed: () => onTaskAction(task.id, 'delete'),
        tooltip: '删除',
      ),
    );
    
    return buttons;
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting:
        return Colors.grey;
      case DownloadStatus.gettingUrl:
      case DownloadStatus.downloading:
      case DownloadStatus.downloadingAudio:
      case DownloadStatus.gettingDanmaku:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getStatusTextColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.waiting:
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.gettingUrl:
      case DownloadStatus.downloading:
      case DownloadStatus.downloadingAudio:
      case DownloadStatus.gettingDanmaku:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }
}