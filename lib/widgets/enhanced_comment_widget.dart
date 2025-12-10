import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment_info.dart';
import '../services/comment_state_service.dart';
import '../services/theme_service.dart';
import '../widgets/enhanced_comment_input.dart';
import '../widgets/emote_panel.dart';
import '../widgets/media_preview.dart';

/// 增强评论组件 - 参考BLVD项目的UI设计
class EnhancedCommentWidget extends StatefulWidget {
  final CommentInfo comment;
  final String oid;
  final String? parentRpid;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onMoreActions;
  final int? maxLines;

  const EnhancedCommentWidget({
    Key? key,
    required this.comment,
    required this.oid,
    this.parentRpid,
    this.isReply = false,
    this.onReply,
    this.onMoreActions,
    this.maxLines,
  }) : super(key: key);

  @override
  State<EnhancedCommentWidget> createState() => _EnhancedCommentWidgetState();
}

class _EnhancedCommentWidgetState extends State<EnhancedCommentWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isExpanded = false;
  final TapGestureRecognizer _userTapRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _topicTapRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _urlTapRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _userTapRecognizer.dispose();
    _topicTapRecognizer.dispose();
    _urlTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final commentStateService = Provider.of<CommentStateService>(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: widget.isReply ? 4 : 12,
        left: widget.isReply ? 32 : 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: widget.isReply 
            ? (themeService.isDarkMode 
                ? Colors.grey.shade800 
                : Colors.grey.shade50)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(),
          const SizedBox(height: 8),
          _buildCommentContent(),
          if (widget.comment.medias != null && widget.comment.medias!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMediaGrid(),
          ],
          const SizedBox(height: 8),
          _buildCommentActions(),
          if (widget.comment.replies != null && widget.comment.replies!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRepliesSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 2),
              _buildCommentMeta(),
            ],
          ),
        ),
        _buildActionMenu(),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: () => _showUserProfile(widget.comment.user?.mid),
      child: Stack(
        children: [
          CircleAvatar(
            radius: widget.isReply ? 16 : 20,
            backgroundImage: CachedNetworkImageProvider(
              widget.comment.user?.face ?? '',
            ),
            backgroundColor: Colors.grey.shade300,
          ),
          if (widget.comment.user?.pendant != null)
            Positioned(
              right: -8,
              bottom: -8,
              child: CachedNetworkImage(
                imageUrl: widget.comment.user!.pendant!.image,
                width: 20,
                height: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = widget.comment.user;
    if (user == null) return const SizedBox();

    return Row(
      children: [
        Flexible(
          child: Text(
            user.uname,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.isReply ? 12 : 14,
              color: user.vip?.status == 1 ? Colors.pink : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user.level > 0) ...[
          const SizedBox(width: 4),
          _buildLevelBadge(user.level),
        ],
        if (user.official != null) ...[
          const SizedBox(width: 4),
          _buildOfficialBadge(user.official!),
        ],
        if (user.vip?.status == 1) ...[
          const SizedBox(width: 4),
          _buildVipBadge(user.vip!),
        ],
        if (widget.comment.isUpSelect) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              '精选',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLevelBadge(int level) {
    Color badgeColor;
    if (level >= 6) {
      badgeColor = const Color(0xFFFB7299);
    } else if (level >= 4) {
      badgeColor = const Color(0xFF9B59B6);
    } else if (level >= 2) {
      badgeColor = const Color(0xFF3498DB);
    } else {
      badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'Lv$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOfficialBadge(OfficialInfo official) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        official.text.isNotEmpty ? official.text : '认证',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildVipBadge(VipInfo vip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        vip.label?.text ?? 'VIP',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildCommentMeta() {
    return Row(
      children: [
        Text(
          timeago.format(
            DateTime.fromMillisecondsSinceEpoch(widget.comment.createTime * 1000),
            locale: 'zh',
          ),
          style: TextStyle(
            fontSize: widget.isReply ? 10 : 12,
            color: Colors.grey.shade500,
          ),
        ),
        if (widget.comment.device != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              widget.comment.device!,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
        if (widget.comment.location != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.location_on,
            size: 10,
            color: Colors.grey.shade500,
          ),
          Text(
            widget.comment.location!,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentContent() {
    return GestureDetector(
      onTap: () => _showCommentActions(),
      onLongPress: () => _showCommentActions(),
      child: Padding(
        padding: EdgeInsets.only(left: widget.isReply ? 52 : 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageText(),
            if (widget.comment.replyCount > 0 && widget.comment.replies == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildReplyPrompt(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          _parseCommentMessage(widget.comment.message),
          maxLines: widget.maxLines ?? (_isExpanded ? null : 3),
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: widget.isReply ? 12 : 14,
            height: 1.4,
          ),
        ),
        if (!_isExpanded && widget.maxLines == null && 
            _shouldShowExpandButton(widget.comment.message))
          GestureDetector(
            onTap: () => setState(() => _isExpanded = true),
            child: Text(
              '展开全文',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  WidgetSpan _parseEmoteText(String text, Map<String, EmoteItem> emoteCache) {
    final emote = emoteCache[text];
    if (emote != null) {
      return WidgetSpan(
        child: CachedNetworkImage(
          imageUrl: emote.url,
          width: 20.0,
          height: 20.0,
          placeholder: (context, url) => Container(
            width: 20.0,
            height: 20.0,
            color: Colors.grey.shade300,
          ),
          errorWidget: (context, url, error) => Text(text),
        ),
      );
    }
    return TextSpan(text: text);
  }

  InlineSpan _parseCommentMessage(String message) {
    final commentStateService = Provider.of<CommentStateService>(context, listen: false);
    final emoteCache = commentStateService.emoteCache;
    
    // 解析表情包和@用户等富文本内容
    final textSpans = <InlineSpan>[];
    final regex = RegExp(r'(\[.*?\]|@.*?|#.*?#|https?://[^\s]+)');
    
    int lastEnd = 0;
    for (final match in regex.allMatches(message)) {
      // 添加普通文本
      if (match.start > lastEnd) {
        textSpans.add(TextSpan(text: message.substring(lastEnd, match.start)));
      }
      
      final matchedText = match.group(0)!;
      
      if (matchedText.startsWith('[') && matchedText.endsWith(']')) {
        // 表情包
        textSpans.add(_parseEmoteText(matchedText, emoteCache));
      } else if (matchedText.startsWith('@')) {
        // @用户
        textSpans.add(TextSpan(
          text: matchedText,
          style: TextStyle(color: Theme.of(context).primaryColor),
          recognizer: _userTapRecognizer..onTap = () => _showUserDetail(matchedText.substring(1)),
        ));
      } else if (matchedText.startsWith('#') && matchedText.endsWith('#')) {
        // 话题
        textSpans.add(TextSpan(
          text: matchedText,
          style: TextStyle(color: Theme.of(context).primaryColor),
          recognizer: _topicTapRecognizer..onTap = () => _showTopic(matchedText.substring(1, matchedText.length - 1)),
        ));
      } else if (matchedText.startsWith('http')) {
        // 链接
        textSpans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: _urlTapRecognizer..onTap = () => _openUrl(matchedText),
        ));
      } else {
        textSpans.add(TextSpan(text: matchedText));
      }
      
      lastEnd = match.end;
    }
    
    if (lastEnd < message.length) {
      textSpans.add(TextSpan(text: message.substring(lastEnd)));
    }
    
    return TextSpan(children: textSpans);
  }

  Widget _buildMediaGrid() {
    final medias = widget.comment.medias!;
    return Padding(
      padding: EdgeInsets.only(left: widget.isReply ? 52 : 60),
      child: MediaPreviewGrid(
        medias: medias,
        onTap: (media) => _showMediaPreview(media),
      ),
    );
  }

  Widget _buildReplyPrompt() {
    return TextButton.icon(
      onPressed: widget.onReply,
      icon: const Icon(Icons.expand_more, size: 16),
      label: Text('查看${widget.comment.replyCount}条回复'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildRepliesSection() {
    return Padding(
      padding: EdgeInsets.only(left: widget.isReply ? 52 : 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示热门回复（如果有的话）
          if (widget.comment.replies != null && widget.comment.replies!.isNotEmpty) ...[
            ...widget.comment.replies!.take(3).map((reply) => 
              EnhancedCommentWidget(
                comment: reply,
                oid: widget.oid,
                parentRpid: widget.comment.rpid,
                isReply: true,
                maxLines: 2,
              ),
            ),
          ],
          
          // 查看全部回复按钮
          if (widget.comment.replyCount > (widget.comment.replies?.length ?? 0))
            TextButton(
              onPressed: widget.onReply,
              child: Text(
                widget.comment.replyCount > (widget.comment.replies?.length ?? 0) 
                    ? '查看全部${widget.comment.replyCount}条回复'
                    : '${widget.comment.replyCount}条回复'
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentActions() {
    final commentStateService = Provider.of<CommentStateService>(context);
    
    return Padding(
      padding: EdgeInsets.only(left: widget.isReply ? 52 : 60),
      child: Row(
        children: [
          _buildActionButton(
            icon: AnimatedBuilder(
              animation: _likeAnimation,
              builder: (context, child) => Transform.scale(
                scale: widget.comment.isLiked ? _likeAnimation.value : 1.0,
                child: Icon(
                  widget.comment.isLiked 
                      ? Icons.thumb_up 
                      : Icons.thumb_up_outlined,
                  size: 16,
                ),
              ),
            ),
            count: widget.comment.formattedLike,
            onTap: () async {
              if (widget.comment.isLiked) {
                _likeAnimationController.reverse();
              } else {
                _likeAnimationController.forward().then((_) {
                  _likeAnimationController.reverse();
                });
              }
              await commentStateService.toggleLike(
                oid: widget.oid,
                comment: widget.comment,
              );
            },
            isActive: widget.comment.isLiked,
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: const Icon(Icons.comment_outlined, size: 16),
            count: widget.comment.formattedReplyCount,
            onTap: widget.onReply,
          ),
          if (!widget.isReply) ...[
            const SizedBox(width: 16),
            _buildActionButton(
              icon: const Icon(Icons.share_outlined, size: 16),
              count: '',
              onTap: _shareComment,
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: const Icon(Icons.more_horiz, size: 16),
              count: '',
              onTap: widget.onMoreActions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String count,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                color: isActive 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('复制'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, size: 16),
              SizedBox(width: 8),
              Text('举报'),
            ],
          ),
        ),
        if (!widget.isReply)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 8),
                Text('删除'),
              ],
            ),
          ),
      ],
      child: const Icon(Icons.more_vert, size: 16),
    );
  }

  bool _shouldShowExpandButton(String message) {
    // 简单判断是否需要展开按钮
    return message.length > 100 || message.split('\n').length > 3;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy':
        _copyComment();
        break;
      case 'report':
        _reportComment();
        break;
      case 'delete':
        _deleteComment();
        break;
    }
  }

  void _showUserProfile(String? mid) {
    if (mid != null) {
      // 跳转到用户主页
      debugPrint('查看用户主页: $mid');
    }
  }

  void _showUserDetail(String username) {
    // 查看@用户详情
    debugPrint('查看用户详情: $username');
  }

  void _showTopic(String topic) {
    // 查看话题
    debugPrint('查看话题: $topic');
  }

  void _openUrl(String url) {
    // 打开链接
    debugPrint('打开链接: $url');
  }

  void _showMediaPreview(MediaInfo media) {
    // 显示媒体预览
    debugPrint('显示媒体预览: ${media.url}');
  }

  void _showCommentActions() {
    // 显示评论操作菜单
    debugPrint('显示评论操作');
  }

  void _shareComment() {
    // 分享评论
    debugPrint('分享评论');
  }

  void _copyComment() {
    // 复制评论内容
    debugPrint('复制评论内容');
  }

  void _reportComment() {
    // 举报评论
    debugPrint('举报评论');
  }

  void _deleteComment() {
    // 删除评论
    debugPrint('删除评论');
  }
}