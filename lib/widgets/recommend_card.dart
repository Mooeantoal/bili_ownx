import 'package:flutter/material.dart';
import '../models/bili_video_info.dart';
import '../utils/string_format_utils.dart';

/// 推荐视频卡片 - 完全基于bili_you设计
class RecommendCard extends StatelessWidget {
  const RecommendCard({
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
    TextStyle playInfoTextStyle = TextStyle(
        color: Theme.of(context).hintColor,
        fontSize: 12,
        overflow: TextOverflow.ellipsis);
    Color iconColor = Theme.of(context).hintColor;

    return Card(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片 - 保持bili_you的16:10宽高比
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _buildImageWidget(context),
                ),
              ),
              
              // 视频信息区域
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题 - 固定高度40*textScaleFactor
                    SizedBox(
                      height: 40 * MediaQuery.of(context).textScaleFactor,
                      child: Text(
                        video.title,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 播放信息行 - 图标+数字的富文本组合
                    Text.rich(
                      TextSpan(children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.slideshow_rounded,
                            color: iconColor,
                            size: 12 * MediaQuery.of(context).textScaleFactor,
                          ),
                        ),
                        TextSpan(
                          text: " ${StringFormatUtils.formatPlayCount(video.play)}  ",
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.format_list_bulleted_rounded,
                            color: iconColor,
                            size: 12 * MediaQuery.of(context).textScaleFactor,
                          ),
                        ),
                        TextSpan(
                          text: " ${StringFormatUtils.formatDanmakuCount(video.danmaku)} ",
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.timer_outlined,
                            color: iconColor,
                            size: 12 * MediaQuery.of(context).textScaleFactor,
                          ),
                        ),
                        TextSpan(
                          text: ' ${video.duration}',
                        ),
                      ]),
                      style: playInfoTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // UP主名称
                    Text(
                      video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: playInfoTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 点击层
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        transitionOnUserGestures: true,
        child: _buildCachedImage(context),
      );
    }
    return _buildCachedImage(context);
  }

  Widget _buildCachedImage(BuildContext context) {
    return Image.network(
      video.cover,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: Icon(Icons.error),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}