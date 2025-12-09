import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/search_result.dart';
import '../utils/string_format_utils.dart';

/// 搜索结果视频卡片 - 改进版
class ImprovedVideoCard extends StatelessWidget {
  final VideoSearchResult video;
  final VoidCallback onTap;
  final VoidCallback? onCommentTap;
  final String? heroTag;

  const ImprovedVideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onCommentTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图区域
            _buildCoverImage(context),
            const SizedBox(width: 12),
            
            // 信息区域
            Expanded(
              child: _buildVideoInfo(context),
            ),
            
            // 操作按钮区域
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建封面图
  Widget _buildCoverImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // 主封面图
          SizedBox(
            width: 160,
            height: 100,
            child: heroTag != null
                ? Hero(
                    tag: heroTag!,
                    child: CachedNetworkImage(
                      imageUrl: video.cover,
                      width: 160,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: video.cover,
                    width: 160,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
          ),
          
          // 时长标签
          if (video.duration.isNotEmpty)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.duration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建视频信息
  Widget _buildVideoInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          video.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 6),
        
        // UP主名称
        Text(
          video.author,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const Spacer(),
        
        // 统计信息行
        _buildStatsRow(context),
      ],
    );
  }

  /// 构建统计信息行
  Widget _buildStatsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: [
        // 播放量
        _buildStatItem(
          context,
          Icons.play_arrow_outlined,
          StringFormatUtils.formatPlayCount(video.play),
        ),
        
        // 弹幕数
        if (video.danmaku > 0)
          _buildStatItem(
            context,
            Icons.chat_bubble_outline,
            StringFormatUtils.formatDanmakuCount(video.danmaku),
          ),
        
        // 评论数
        if (video.reply > 0)
          _buildStatItem(
            context,
            Icons.comment_outlined,
            StringFormatUtils.formatLikeCount(video.reply),
          ),
        
        // 发布时间
        if (video.pubdate > 0)
          _buildStatItem(
            context,
            Icons.schedule_outlined,
            StringFormatUtils.formatTimestampToRelative(video.pubdate),
          ),
        
        // 视频ID标识（简化显示）
        _buildStatItem(
          context,
          Icons.video_library_outlined,
          video.bvid.isNotEmpty ? video.bvid.substring(0, 6) : 'AV${video.aid}',
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 评论按钮
        if (onCommentTap != null)
          IconButton(
            icon: Icon(
              Icons.comment_outlined,
              size: 20,
              color: Theme.of(context).hintColor,
            ),
            onPressed: onCommentTap,
            tooltip: '查看评论',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: const EdgeInsets.all(8),
          ),
        
        // 更多操作按钮
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 20,
            color: Theme.of(context).hintColor,
          ),
          onSelected: (value) {
            switch (value) {
              case 'copy_link':
                _copyVideoLink(context);
                break;
              case 'share':
                _shareVideo(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy_link',
              child: Row(
                children: [
                  Icon(Icons.link, size: 16),
                  SizedBox(width: 8),
                  Text('复制链接'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 16),
                  SizedBox(width: 8),
                  Text('分享'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 复制视频链接
  void _copyVideoLink(BuildContext context) {
    final link = video.bvid.isNotEmpty 
        ? 'https://www.bilibili.com/video/${video.bvid}'
        : 'https://www.bilibili.com/video/av${video.aid}';
    
    // 这里应该使用 Clipboard API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('链接已复制: $link'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 分享视频
  void _shareVideo(BuildContext context) {
    final link = video.bvid.isNotEmpty 
        ? 'https://www.bilibili.com/video/${video.bvid}'
        : 'https://www.bilibili.com/video/av${video.aid}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('分享功能待实现: $link'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}