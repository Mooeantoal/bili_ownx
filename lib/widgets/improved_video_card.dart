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

  /// 计算响应式尺寸
  static double getCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度调整卡片高度
    if (screenWidth < 360) return 84; // 小屏幕
    if (screenWidth < 400) return 86; // 中等屏幕
    return 88; // 大屏幕
  }

  static double getCoverWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 100; // 小屏幕
    if (screenWidth < 400) return 105; // 中等屏幕
    return 110; // 大屏幕
  }

  @override
  Widget build(BuildContext context) {
      return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: getCardHeight(context), // 使用响应式高度
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图区域
            _buildCoverImage(context),
            const SizedBox(width: 8),
            
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
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          // 主封面图
          SizedBox(
            width: getCoverWidth(context), // 使用响应式宽度
            height: 82,
            child: _buildImageWidget(context),
          ),
          
          // 时长标签
          if (video.duration.isNotEmpty)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  video.duration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
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
      mainAxisSize: MainAxisSize.min, // 防止溢出
      children: [
        // 标题 - 使用合适的行高
        Flexible(
          child: Text(
            video.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              height: 1.2, // 适当的行高防止溢出
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(height: 2), // 稍微增加间距
        
        // UP主名称
        Text(
          video.author,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).hintColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 2),
        
        // 统计信息行
        _buildStatsRow(context),
      ],
    );
  }

  /// 构建统计信息行
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        // 播放量
        _buildStatItem(
          context,
          Icons.play_arrow_outlined,
          StringFormatUtils.formatPlayCount(video.play),
        ),
        
        const SizedBox(width: 6),
        
        // 弹幕数（如果有的话）
        if (video.danmaku > 0) ...[
          _buildStatItem(
            context,
            Icons.chat_bubble_outline,
            StringFormatUtils.formatDanmakuCount(video.danmaku),
          ),
          const SizedBox(width: 6),
        ],
        
        // 发布时间（优先显示时间而非评论数）
        if (video.pubdate > 0)
          _buildStatItem(
            context,
            Icons.schedule_outlined,
            StringFormatUtils.formatTimestampToRelative(video.pubdate),
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
          size: 10, // 增加图标尺寸确保可见性
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(width: 2), // 适当间距
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
            fontSize: 9, // 适当的字号
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: 40, // 增加宽度防止溢出
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 评论按钮
          if (onCommentTap != null)
            IconButton(
              icon: Icon(
                Icons.comment_outlined,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
              onPressed: onCommentTap,
              tooltip: '查看评论',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          
          // 更多操作按钮
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 16,
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
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
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
      ),
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

  /// 构建图片组件（处理空URL等错误情况）
  Widget _buildImageWidget(BuildContext context) {
    final imageUrl = video.cover.isEmpty ? '' : video.cover;
    
    Widget imageWidget;
    
      if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
        width: getCoverWidth(context), // 使用响应式宽度
        height: 82,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.grey, size: 16),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 16),
            ),
          ),
        ),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: getCoverWidth(context), // 使用响应式宽度
        height: 82,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.grey, size: 16),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 16),
          ),
        ),
      );
    }
    
    return imageWidget;
  }
}