import 'package:flutter/material.dart';
import '../models/download_option.dart';
import '../models/video_info.dart';
import '../services/download_manager.dart';

class DownloadOptionPage extends StatefulWidget {
  final VideoInfo videoInfo;
  final int partIndex;

  const DownloadOptionPage({
    super.key,
    required this.videoInfo,
    required this.partIndex,
  });

  @override
  State<DownloadOptionPage> createState() => _DownloadOptionPageState();
}

class _DownloadOptionPageState extends State<DownloadOptionPage> {
  DownloadType _selectedType = DownloadType.combined;
  int _selectedQuality = 80;
  String _selectedQualityName = '高清 1080P';
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final part = widget.videoInfo.parts[widget.partIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载选项'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.partTitle.isEmpty ? widget.videoInfo.title : part.partTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UP主: ${widget.videoInfo.author ?? '未知'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (part.duration > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '时长: ${part.duration}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 下载类型选择
            const Text(
              '下载类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...DownloadOption.options.map((option) {
              return RadioListTile<DownloadType>(
                title: Text(option.name),
                subtitle: Text(option.description),
                value: option.type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              );
            }).toList(),

            const SizedBox(height: 24),

            // 画质选择
            const Text(
              '画质选择',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.videoInfo.qualities.map((quality) {
                final isSelected = _selectedQuality == quality.qn;
                return FilterChip(
                  label: Text(quality.desc),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedQuality = quality.qn;
                      _selectedQualityName = quality.desc;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.pink[100],
                  checkmarkColor: Colors.pink,
                );
              }).toList(),
            ),

            const Spacer(),

            // 下载按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDownloading ? null : _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isDownloading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('添加到下载队列...'),
                        ],
                      )
                    : const Text(
                        '开始下载',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final part = widget.videoInfo.parts[widget.partIndex];
      
      await DownloadManager().addDownloadTask(
        bvid: widget.videoInfo.bvid,
        cid: part.cid,
        title: widget.videoInfo.title,
        cover: widget.videoInfo.cover,
        author: widget.videoInfo.author,
        quality: _selectedQuality,
        qualityName: _selectedQualityName,
        partIndex: widget.partIndex,
        partTitle: part.partTitle,
        downloadType: _selectedType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已添加到下载队列'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加下载任务失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}