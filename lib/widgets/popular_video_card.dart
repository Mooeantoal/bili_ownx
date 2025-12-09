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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: 90, // 完全匹配bili_you的高度
        child: Row(
          children: [
            // 封面区域 - 160x100
            SizedBox(
              width: 160,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    _buildImageWidget(context),
                    // 时长标签 - 右下角显示，带阴影
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          video.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            shadows: [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 10,
                                spreadRadius: 10,
                              ),
                            ],
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
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // UP主名称
                    Text(
                      video.author,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    
                    // 播放信息和时间
                    Row(
                      children: [
                        Icon(
                          Icons.slideshow_rounded,
                          size: 14, 
                          color: Theme.of(context).hintColor,
                        ),
                        Text(
                          StringFormatUtils.formatPlayCount(video.play),
                          style: TextStyle(
                            fontSize: 12, 
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const Text("  "),
                        Text(
                          StringFormatUtils.formatTimestampToRelative(video.pubdate),
                          style: TextStyle(
                            fontSize: 12, 
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
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
    Widget imageWidget = Image.network(
      video.cover,
      width: 160,
      height: 100,
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