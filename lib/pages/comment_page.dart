import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/comment_api.dart';
import '../models/comment_info.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import '../services/network_service.dart';
import '../widgets/network_status_widget.dart';

/// 评论页面
class CommentPage extends StatefulWidget {
  final String bvid;
  final String? aid; // 改为字符串类型以支持大数值

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
  final ScrollController _scrollController = ScrollController();
  final NetworkService _networkService = NetworkService();
  
  late TabController _tabController;
  late NetworkStatusListener _networkListener;
  
  Map<String, dynamic>? _commentResponse;
  List<CommentInfo> _comments = [];
  int _currentSort = 0; // 0:热门 1:最新 2:最热
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  Map<String, List<CommentInfo>> _replyCache = {};
  Map<String, bool> _replyLoading = {};
  Map<String, bool> _replyError = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNetworkListener();
    _loadComments();
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
    
    // 添加滚动监听
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _networkListener.dispose();
    super.dispose();
  }

  /// 初始化网络监听
  void _initializeNetworkListener() {
    _networkListener = NetworkStatusListener(
      _networkService,
      onStatusChanged: (status) {
        if (mounted) {
          if (status == NetworkStatus.online && _comments.isEmpty) {
            // 网络恢复且没有评论时重新加载
            _loadComments(refresh: true);
          }
        }
      },
    );
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore && !_isLoading) {
        _loadComments();
      }
    }
  }

  /// 加载评论
  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      if (refresh) {
        _isRefreshing = true;
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final response = await _networkService.executeWithNetworkCheck(
        () => _commentApi.getVideoComments(
          oid: widget.aid?.toString() ?? widget.bvid,
          sort: _currentSort,
          pageNum: _currentPage,
          pageSize: 20,
        ),
        timeout: const Duration(seconds: 15),
        retryCount: 2,
      );

      if (mounted) {
        final comments = response['replies'] as List<dynamic>? ?? [];
        final parsedComments = comments
            .whereType<Map<String, dynamic>>()
            .map((json) => CommentInfo.fromJson(json))
            .toList();
            
        setState(() {
          if (refresh) {
            _comments = parsedComments;
          } else {
            _comments.addAll(parsedComments);
          }

          _commentResponse = response;
          _hasMore = parsedComments.length >= 20;
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isRefreshing = false;
          _errorMessage = e.toString();
        });
        
        // 根据网络状态显示不同的错误信息
        if (_networkService.isOffline) {
          _showNetworkErrorSnackBar();
        } else {
          _showErrorSnackBar('加载评论失败: $e');
        }
      }
    }
  }

  /// 加载回复
  Future<void> _loadReplies(CommentInfo comment) async {
    if (_replyCache.containsKey(comment.rpid)) return;

    setState(() {
      _replyLoading[comment.rpid] = true;
      _replyError.remove(comment.rpid);
    });

    try {
      final response = await _networkService.executeWithNetworkCheck(
        () => _commentApi.getCommentReplies(
          oid: widget.aid?.toString() ?? widget.bvid,
          rpid: comment.rpid,
        ),
        timeout: const Duration(seconds: 10),
      );

      if (mounted) {
        final replies = response['replies'] as List<dynamic>? ?? [];
        final parsedReplies = replies
            .whereType<Map<String, dynamic>>()
            .map((json) => CommentInfo.fromJson(json))
            .toList();
            
        setState(() {
          _replyCache[comment.rpid] = parsedReplies;
          _replyLoading[comment.rpid] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _replyLoading[comment.rpid] = false;
          _replyError[comment.rpid] = true;
        });
        
        if (_networkService.isOffline) {
          _showNetworkErrorSnackBar();
        } else {
          _showErrorSnackBar('加载回复失败: $e');
        }
      }
    }
  }

  /// 发送评论
  Future<void> _sendComment({String? parentRpid}) async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    // 显示发送中状态
    _showSendingSnackBar();

    try {
      await _networkService.executeWithNetworkCheck(
        () => _commentApi.sendComment(
          message: message,
          oid: widget.aid?.toString() ?? widget.bvid,
          parent: parentRpid,
        ),
        timeout: const Duration(seconds: 10),
      );

      _commentController.clear();
      _loadComments(refresh: true);
      _showSuccessSnackBar('评论发送成功');
    } catch (e) {
      if (_networkService.isOffline) {
        _showNetworkErrorSnackBar();
      } else {
        _showErrorSnackBar('发送评论失败: $e');
      }
    }
  }

  /// 点赞评论
  Future<void> _likeComment(CommentInfo comment) async {
    try {
      final success = await _networkService.executeWithNetworkCheck(
        () => _commentApi.likeComment(
          oid: widget.aid?.toString() ?? widget.bvid,
          rpid: comment.rpid,
          action: comment.isLiked ? 0 : 1,
        ),
        timeout: const Duration(seconds: 5),
      );

      if (success && mounted) {
        setState(() {
          comment.isLiked = !comment.isLiked;
          comment.like += comment.isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      if (_networkService.isOffline) {
        _showNetworkErrorSnackBar();
      } else {
        _showErrorSnackBar('操作失败: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () => _loadComments(refresh: true),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSendingSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text('发送中...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showNetworkErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('网络连接已断开，请检查网络设置'),
          ],
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () {
            _networkService.checkConnectivity();
            if (_networkService.isOnline) {
              _loadComments(refresh: true);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('评论 (${_commentResponse?['total'] ?? _commentResponse?['count'] ?? 0})'),
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
          // 网络状态指示器
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NetworkStatusWidget(
              showLabel: false,
              onlineColor: Colors.green,
              offlineColor: Colors.red,
            ),
          ),
          // 刷新按钮
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () => _loadComments(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 网络状态栏
          NetworkStatusBar(
            height: 24,
            animationDuration: const Duration(milliseconds: 300),
          ),
          // 主内容区域
          Expanded(
            child: _buildBody(),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _comments.isEmpty) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null && _comments.isEmpty) {
      return _buildErrorWidget();
    }

    if (_comments.isEmpty && !_isLoading) {
      return _buildEmptyWidget();
    }

    return _buildCommentList();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载评论...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '未知错误',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadComments(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
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

  Widget _buildCommentList() {
    return RefreshIndicator(
      onRefresh: () => _loadComments(refresh: true),
      child: NetworkListView(
        controller: _scrollController,
        children: _comments.map((comment) => _buildCommentItem(comment)).toList(),
        hasMore: _hasMore,
        loadingWidget: _isLoadingMore 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            : null,
        onLoadMore: _hasMore ? () => _loadComments() : null,
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
    final isLoading = _replyLoading[comment.rpid] == true;
    final hasError = _replyError[comment.rpid] == true;
    final replies = _replyCache[comment.rpid];

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(left: 52),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('加载回复中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.only(left: 52),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            const Text('加载失败', style: TextStyle(color: Colors.red, fontSize: 12)),
            TextButton(
              onPressed: () => _loadReplies(comment),
              child: const Text('重试', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (replies == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 52),
        child: TextButton.icon(
          onPressed: () => _loadReplies(comment),
          icon: const Icon(Icons.expand_more, size: 16),
          label: Text('查看${comment.replyCount}条回复'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...replies.take(3).map((reply) => _buildReplyItem(reply)),
          if (comment.replyCount > 3)
            TextButton(
              onPressed: () => _showRepliesDialog(comment),
              child: Text('查看全部${comment.replyCount}条回复'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Consumer<NetworkService>(
        builder: (context, networkService, child) {
          final canSend = networkService.isOnline && _commentController.text.trim().isNotEmpty;
          
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: networkService.isOnline,
                  decoration: InputDecoration(
                    hintText: networkService.isOnline ? '写下你的评论...' : '网络连接已断开',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    filled: !networkService.isOnline,
                    fillColor: Colors.grey.shade100,
                  ),
                  maxLines: null,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: canSend ? () => _sendComment() : null,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: canSend 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
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

      final replies = response['replies'] as List<dynamic>? ?? [];
      final parsedReplies = replies
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentInfo.fromJson(json))
          .toList();
          
      setState(() {
        _replies.addAll(parsedReplies);
        _hasMore = parsedReplies.length >= 10;
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