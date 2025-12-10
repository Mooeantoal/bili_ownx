import 'package:flutter/material.dart';
import '../models/bili_video_info.dart';
import '../utils/string_format_utils.dart';

/// 热门视频卡片 - 完全基于bili_you的VideoTileItem设计
class PopularVideoCard extends StatelessWidget {
  const PopularVideoCard({
    super.key,
    required this.video,
    required this.heroTag,
    required this.onTap,
  });

  final BiliVideoInfo video;
  final String? heroTag;
  final VoidCallback onTap;

  /// 计算响应式尺寸
  static double getCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 90;  // 小屏幕
    if (screenWidth < 400) return 95;  // 中等屏幕
    return 100; // 大屏幕
  }

  static double getCoverWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 120;  // 小屏幕
    if (screenWidth < 400) return 130;  // 中等屏幕
    return 140; // 大屏幕
  }

  static double getCoverHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 640) return 75;  // 小屏幕
    if (screenHeight < 800) return 82;  // 中等屏幕
    return 90; // 大屏幕
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = getCardHeight(context);
    final coverWidth = getCoverWidth(context);
    final coverHeight = getCoverHeight(context);
    
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: cardHeight,
        child: Row(
          children: [
            // 封面区域 - 响应式尺寸
            SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    _buildImageWidget(context),
                    // 时长标签 - 右下角显示，带背景
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          video.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 信息区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 防止溢出
                  children: [
                    // 标题 - 使用Flexible防止溢出
                    Flexible(
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    
                    const SizedBox(height: 2), // 减小间距
                    
                    // UP主名称
                    Text(
                      video.author,
                      style: TextStyle(
                        fontSize: 11, 
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 播放信息和时间 - 使用Expanded防止溢出
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.slideshow_rounded,
                            size: 12, // 减小图标尺寸
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              StringFormatUtils.formatPlayCount(video.play),
                              style: TextStyle(
                                fontSize: 11, 
                                color: Theme.of(context).hintColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text("  "),
                          Text(
                            StringFormatUtils.formatTimestampToRelative(video.pubdate),
                            style: TextStyle(
                              fontSize: 11, 
                              color: Theme.of(context).hintColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    final coverWidth = getCoverWidth(context);
    final coverHeight = getCoverHeight(context);
    
    Widget imageWidget = Image.network(
      video.cover,
      width: coverWidth,
      height: coverHeight,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
        );
      },
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        transitionOnUserGestures: true,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}