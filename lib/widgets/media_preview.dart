import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment_info.dart';

/// 媒体预览网格 - 参考BLVD项目
class MediaPreviewGrid extends StatelessWidget {
  final List<MediaInfo> medias;
  final Function(MediaInfo)? onTap;
  final int maxItems;

  const MediaPreviewGrid({
    Key? key,
    required this.medias,
    this.onTap,
    this.maxItems = 9,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) return const SizedBox();

    final displayMedias = medias.take(maxItems).toList();
    final itemCount = displayMedias.length;
    
    // 根据数量决定网格布局
    int crossAxisCount;
    double aspectRatio;
    
    switch (itemCount) {
      case 1:
        crossAxisCount = 1;
        aspectRatio = 16 / 9;
        break;
      case 2:
        crossAxisCount = 2;
        aspectRatio = 1;
        break;
      case 3:
        crossAxisCount = 3;
        aspectRatio = 1;
        break;
      default:
        crossAxisCount = 3;
        aspectRatio = 1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: displayMedias.length,
      itemBuilder: (context, index) {
        final media = displayMedias[index];
        return _buildMediaItem(media, index, itemCount);
      },
    );
  }

  Widget _buildMediaItem(MediaInfo media, int index, int totalCount) {
    Widget child;

    switch (media.type.toLowerCase()) {
      case 'image':
        child = _buildImageItem(media);
        break;
      case 'video':
        child = _buildVideoItem(media);
        break;
      default:
        child = _buildUnknownItem(media);
    }

    return GestureDetector(
      onTap: () => onTap?.call(media),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Stack(
          children: [
            child,
            if (index == totalCount - 1 && totalCount > maxItems)
              _buildMoreIndicator(totalCount),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(MediaInfo media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: media.thumbnail ?? media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey.shade400,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(MediaInfo media) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: media.thumbnail ?? media.url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.videocam_off, size: 32),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white70,
              size: 48,
            ),
          ),
        ),
        if (media.description != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Text(
                media.description!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnknownItem(MediaInfo media) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(media.type),
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              media.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(int totalCount) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '+${totalCount - (maxItems - 1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }
}

/// 媒体预览对话框
class MediaPreviewDialog extends StatefulWidget {
  final List<MediaInfo> medias;
  final int initialIndex;

  const MediaPreviewDialog({
    Key? key,
    required this.medias,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TransformationController _transformationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 背景遮罩
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),
          ),
          
          // 主要内容
          if (widget.medias.isNotEmpty)
            Positioned.fill(
              child: _buildMediaViewer(),
            ),
          
          // 顶部操作栏
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),
          
          // 底部信息栏
          if (widget.medias[_currentIndex].description != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _buildBottomInfo(),
            ),
          
          // 页码指示器
          if (widget.medias.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _buildPageIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaViewer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
        _transformationController.value = Matrix4.identity();
      },
      itemCount: widget.medias.length,
      itemBuilder: (context, index) {
        final media = widget.medias[index];
        return _buildMediaPage(media);
      },
    );
  }

  Widget _buildMediaPage(MediaInfo media) {
    switch (media.type.toLowerCase()) {
      case 'image':
        return _buildImagePage(media);
      case 'video':
        return _buildVideoPage(media);
      default:
        return _buildUnsupportedPage(media);
    }
  }

  Widget _buildImagePage(MediaInfo media) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: media.url,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPage(MediaInfo media) {
    return Stack(
      children: [
        Center(
          child: CachedNetworkImage(
            imageUrl: media.thumbnail ?? media.url,
            fit: BoxFit.contain,
          ),
        ),
        const Positioned.fill(
          child: Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white70,
              size: 64,
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '视频播放功能待实现',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedPage(MediaInfo media) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(media.type),
            color: Colors.white70,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            '不支持的文件类型: ${media.type}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        if (widget.medias[_currentIndex].type == 'image')
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMediaAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('保存图片'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
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

  Widget _buildBottomInfo() {
    final media = widget.medias[_currentIndex];
    if (media.description == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        media.description!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${_currentIndex + 1} / ${widget.medias.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  void _handleMediaAction(String action) {
    switch (action) {
      case 'save':
        _saveImage();
        break;
      case 'share':
        _shareImage();
        break;
    }
  }

  void _saveImage() {
    // 实现保存图片功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存功能待实现')),
    );
  }

  void _shareImage() {
    // 实现分享图片功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能待实现')),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }
}