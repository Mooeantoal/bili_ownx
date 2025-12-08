import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/comment_api.dart';
import '../models/comment_info.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';

/// 评论页面
class CommentPage extends StatefulWidget {
  final String bvid;
  final int? aid;

  const CommentPage({
    super.key,
    required this.bvid,
    this.aid,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage>
    with TickerProviderStateMixin {
  final CommentApi _commentApi = CommentApi();
  final TextEditingController _commentController = TextEditingController();
  
  late TabController _tabController;
  
  CommentResponse? _commentResponse;
  List<CommentInfo> _comments = [];
  int _currentSort = 0; // 0:热门 1:最新 2:最热
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  Map<String, List<CommentInfo>> _replyCache = {};
  Map<String, bool> _replyLoading = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadComments();
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = refresh ? true : _isLoadingMore;
    });

    try {
      final response = await _commentApi.getVideoComments(
        oid: widget.aid?.toString() ?? widget.bvid,
        sort: _currentSort,
        pageNum: _currentPage,
        pageSize: 20,
      );

      if (refresh) {
        _comments = response.comments;
      } else {
        _comments.addAll(response.comments);
      }

      _commentResponse = response;
      _hasMore = response.comments.length >= 20;
      _currentPage++;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showErrorSnackBar('加载评论失败: $e');
      }
    }
  }

  Future<void> _loadReplies(CommentInfo comment) async {
    if (_replyCache.containsKey(comment.rpid)) return;

    setState(() {
      _replyLoading[comment.rpid] = true;
    });

    try {
      final response = await _commentApi.getCommentReplies(
        oid: widget.aid?.toString() ?? widget.bvid,
        rpid: comment.rpid,
      );

      setState(() {
        _replyCache[comment.rpid] = response.replies;
        _replyLoading[comment.rpid] = false;
      });
    } catch (e) {
      setState(() {
        _replyLoading[comment.rpid] = false;
      });
      _showErrorSnackBar('加载回复失败: $e');
    }
  }

  Future<void> _sendComment({String? parentRpid}) async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    try {
      await _commentApi.sendComment(
        message: message,
        oid: widget.aid?.toString() ?? widget.bvid,
        parent: parentRpid,
      );

      _commentController.clear();
      _loadComments(refresh: true);
      _showSuccessSnackBar('评论发送成功');
    } catch (e) {
      _showErrorSnackBar('发送评论失败: $e');
    }
  }

  Future<void> _likeComment(CommentInfo comment) async {
    try {
      final success = await _commentApi.likeComment(
        oid: widget.aid?.toString() ?? widget.bvid,
        rpid: comment.rpid,
        action: comment.isLiked ? 0 : 1,
      );

      if (success) {
        setState(() {
          comment.isLiked = !comment.isLiked;
          comment.like += comment.isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      _showErrorSnackBar('操作失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('评论 (${_commentResponse?.totalCount ?? 0})'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentSort = index;
            });
            _loadComments(refresh: true);
          },
          tabs: const [
            Tab(text: '热门'),
            Tab(text: '最新'),
            Tab(text: '最热'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadComments(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCommentList(),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    if (_comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无评论', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadComments(refresh: true),
      child: ListView.builder(
        itemCount: _comments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              _loadComments();
              return const SizedBox.shrink();
            }
          }

          final comment = _comments[index];
          return _buildCommentItem(comment);
        },
      ),
    );
  }

  Widget _buildCommentItem(CommentInfo comment) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeService.isDarkMode 
                ? Colors.grey.shade800 
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(comment),
          const SizedBox(height: 8),
          _buildCommentContent(comment),
          if (comment.replyCount > 0) ...[
            const SizedBox(height: 8),
            _buildRepliesSection(comment),
          ],
          const SizedBox(height: 8),
          _buildCommentActions(comment),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(CommentInfo comment) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: CachedNetworkImageProvider(
            comment.user?.face ?? '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.user?.uname ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (comment.user?.level != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'Lv${comment.user!.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                timeago.format(
                  DateTime.fromMillisecondsSinceEpoch(comment.createTime * 1000),
                  locale: 'zh',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (comment.isTop || comment.isFloorTop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '置顶',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentContent(CommentInfo comment) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.message,
            style: const TextStyle(fontSize: 14),
          ),
          if (comment.replies != null && comment.replies!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies!.take(2).map((reply) => _buildReplyItem(reply)),
            if (comment.replyCount > 2)
              TextButton(
                onPressed: () => _showRepliesDialog(comment),
                child: Text('查看${comment.replyCount - 2}条回复'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(CommentInfo reply) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${reply.user?.uname ?? ''}: ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Expanded(
                child: Text(
                  reply.message,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          Text(
            timeago.format(
              DateTime.fromMillisecondsSinceEpoch(reply.createTime * 1000),
              locale: 'zh',
            ),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection(CommentInfo comment) {
    if (_replyLoading[comment.rpid] == true) {
      return const Padding(
        padding: EdgeInsets.only(left: 52),
        child: LinearProgressIndicator(),
      );
    }

    final replies = _replyCache[comment.rpid];
    if (replies == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 52),
        child: TextButton(
          onPressed: () => _loadReplies(comment),
          child: Text('查看${comment.replyCount}条回复'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...replies.take(3).map((reply) => _buildReplyItem(reply)),
          if (replies.length > 3)
            TextButton(
              onPressed: () => _showRepliesDialog(comment),
              child: Text('查看更多回复'),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentActions(CommentInfo comment) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _likeComment(comment),
            icon: Icon(
              comment.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
            ),
            label: Text('${comment.like}'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showReplyDialog(comment),
            icon: const Icon(Icons.comment_outlined, size: 16),
            label: Text('${comment.replyCount}'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '写下你的评论...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendComment(),
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(CommentInfo comment) {
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        comment: comment,
        onReply: (message) async {
          await _commentApi.sendComment(
            message: message,
            oid: widget.aid?.toString() ?? widget.bvid,
            parent: comment.rpid,
          );
          _loadComments(refresh: true);
        },
      ),
    );
  }

  void _showRepliesDialog(CommentInfo comment) {
    showDialog(
      context: context,
      builder: (context) => RepliesDialog(
        comment: comment,
        aid: widget.aid?.toString() ?? widget.bvid,
      ),
    );
  }
}

/// 回复对话框
class ReplyDialog extends StatefulWidget {
  final CommentInfo comment;
  final Function(String) onReply;

  const ReplyDialog({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('回复 ${widget.comment.user?.uname ?? ''}'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: '写下你的回复...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final message = _controller.text.trim();
            if (message.isNotEmpty) {
              widget.onReply(message);
              Navigator.pop(context);
            }
          },
          child: const Text('回复'),
        ),
      ],
    );
  }
}

/// 回复列表对话框
class RepliesDialog extends StatefulWidget {
  final CommentInfo comment;
  final String aid;

  const RepliesDialog({
    super.key,
    required this.comment,
    required this.aid,
  });

  @override
  State<RepliesDialog> createState() => _RepliesDialogState();
}

class _RepliesDialogState extends State<RepliesDialog> {
  final CommentApi _commentApi = CommentApi();
  List<CommentInfo> _replies = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await _commentApi.getCommentReplies(
        oid: widget.aid,
        rpid: widget.comment.rpid,
        pageNum: _currentPage,
      );

      setState(() {
        _replies.addAll(response.replies);
        _hasMore = response.replies.length >= 10;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载回复失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: Text('${widget.comment.replyCount}条回复'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _replies.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _replies.length) {
                    if (_isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else {
                      _loadReplies();
                      return const SizedBox.shrink();
                    }
                  }

                  final reply = _replies[index];
                  return _buildReplyItem(reply);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyItem(CommentInfo reply) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(reply.user?.face ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.user?.uname ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeago.format(
                    DateTime.fromMillisecondsSinceEpoch(reply.createTime * 1000),
                    locale: 'zh',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reply.message),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${reply.like} 赞'),
                    const SizedBox(width: 16),
                    Text(timeago.format(
                      DateTime.fromMillisecondsSinceEpoch(reply.createTime * 1000),
                      locale: 'zh',
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}