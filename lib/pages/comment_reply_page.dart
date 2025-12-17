import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment_info.dart';
import '../services/comment_state_service.dart';
import '../widgets/enhanced_comment_widget.dart';
import '../widgets/enhanced_comment_input.dart';

/// 评论回复详情页面 - 显示完整的回复层级结构
class CommentReplyPage extends StatefulWidget {
  final String oid;
  final CommentInfo rootComment;
  final String rootRpid;

  const CommentReplyPage({
    Key? key,
    required this.oid,
    required this.rootComment,
    required this.rootRpid,
  }) : super(key: key);

  @override
  State<CommentReplyPage> createState() => _CommentReplyPageState();
}

class _CommentReplyPageState extends State<CommentReplyPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _replyController = TextEditingController();
  bool _isLoadingReplies = false;
  List<CommentInfo> _replies = [];
  bool _hasMoreReplies = true;
  int _currentPage = 1;
  String? _replyingToRpid;
  String? _replyingToUsername;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final commentStateService = Provider.of<CommentStateService>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${widget.rootComment.replyCount}条回复'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _replies.length + 2, // +2 for root comment and loading indicator
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 显示根评论
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: EnhancedCommentWidget(
                        comment: widget.rootComment,
                        oid: widget.oid,
                        onReply: () => _showReplyInput(null, null),
                      ),
                    );
                  }
                  
                  if (index == _replies.length + 1) {
                    // 加载更多指示器
                    return _buildLoadMoreIndicator();
                  }
                  
                  // 显示回复
                  final reply = _replies[index - 1];
                  return EnhancedCommentWidget(
                    comment: reply,
                    oid: widget.oid,
                    parentRpid: widget.rootRpid,
                    isReply: true,
                    maxLines: null, // 回复页面显示完整内容
                    onReply: () => _showReplyInput(reply.rpid, reply.user?.uname),
                  );
                },
              ),
            ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMoreReplies) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多回复了',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_isLoadingReplies) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container();
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingToUsername != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Text(
                    '回复 @$_replyingToUsername',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: '发表回复...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendReply,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadReplies({bool refresh = false}) async {
    if (_isLoadingReplies) return;

    setState(() {
      _isLoadingReplies = true;
      if (refresh) {
        _currentPage = 1;
        _replies.clear();
        _hasMoreReplies = true;
      }
    });

    try {
      final commentStateService = 
          Provider.of<CommentStateService>(context, listen: false);
      
      final newReplies = await commentStateService.loadCommentReplies(
        oid: widget.oid,
        rootRpid: widget.rootRpid,
        currentRpid: widget.rootRpid, // 添加当前评论ID用于调试
        pageNum: _currentPage,
        pageSize: 50,
      );

      print('CommentReplyPage加载到${newReplies.length}条回复');

      setState(() {
        if (refresh) {
          _replies = newReplies;
        } else {
          _replies.addAll(newReplies);
        }
        _hasMoreReplies = newReplies.length >= 20;
        _currentPage++;
        _isLoadingReplies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReplies = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载回复失败: $e')),
      );
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        _loadMoreIfNeeded();
      }
    }
    return false;
  }

  void _loadMoreIfNeeded() {
    if (!_isLoadingReplies && _hasMoreReplies) {
      _loadReplies();
    }
  }

  void _showReplyInput(String? rpid, String? username) {
    setState(() {
      _replyingToRpid = rpid;
      _replyingToUsername = username;
    });
    
    // 聚焦输入框
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToRpid = null;
      _replyingToUsername = null;
      _replyController.clear();
    });
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;

    final commentStateService = 
        Provider.of<CommentStateService>(context, listen: false);

    try {
      await commentStateService.sendComment(
        oid: widget.oid,
        message: message,
        parentRpid: _replyingToRpid,
        rootRpid: widget.rootRpid,
      );

      _replyController.clear();
      _cancelReply();
      
      // 重新加载回复列表
      await _loadReplies(refresh: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回复发送成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('回复发送失败: $e')),
      );
    }
  }
}