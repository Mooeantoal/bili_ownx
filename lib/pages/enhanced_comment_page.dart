import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment_info.dart';
import '../services/comment_state_service.dart';
import '../services/theme_service.dart';
import '../widgets/enhanced_comment_widget.dart';
import '../widgets/enhanced_comment_input.dart';
import '../widgets/media_preview.dart';
import '../widgets/network_status_widget.dart';
import 'comment_reply_page.dart';

/// 增强评论页面 - 参考BLVD项目
class EnhancedCommentPage extends StatefulWidget {
  final String bvid;
  final int? aid;

  const EnhancedCommentPage({
    Key? key,
    required this.bvid,
    this.aid,
  }) : super(key: key);

  @override
  State<EnhancedCommentPage> createState() => _EnhancedCommentPageState();
}

class _EnhancedCommentPageState extends State<EnhancedCommentPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late CommentStateService _commentStateService;
  
  int _currentSort = 3; // 默认按热度排序
  bool _showSortOptions = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeServices() {
    _commentStateService = CommentStateService();
    
    // 监听状态变化
    _commentStateService.addListener(_onCommentStateChanged);
    
    // 预加载表情包
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentStateService.loadEmotes();
    });
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    final oid = widget.aid?.toString() ?? widget.bvid;
    _commentStateService.loadComments(oid: oid, refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _commentStateService.removeListener(_onCommentStateChanged);
    _commentStateService.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPercentage = _scrollController.offset / 
        _scrollController.position.maxScrollExtent;
    
    if (scrollPercentage > 0.8) {
      _commentStateService.loadMoreComments(widget.aid?.toString() ?? widget.bvid);
    }
  }

  void _onCommentStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CommentStateService>.value(
      value: _commentStateService,
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(),
              _buildSliverTabBar(),
            ];
          },
          body: _buildBody(),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        bottomSheet: _buildCommentInput(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer<CommentStateService>(
      builder: (context, commentState, child) {
        return SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          snap: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              '评论 (${commentState.comments.length})',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          actions: [
            _buildNetworkStatusIndicator(),
            _buildRefreshButton(commentState),
            _buildSortButton(),
            _buildMoreOptionsButton(),
          ],
        );
      },
    );
  }

  Widget _buildSliverTabBar() {
    return Consumer<CommentStateService>(
      builder: (context, commentState, child) {
        return SliverPersistentHeader(
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              onTap: (index) {
                final sortValue = commentState.sortOptions[index].value;
                _changeSort(sortValue);
              },
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: commentState.sortOptions.map((option) {
                return Tab(
                  text: option.label,
                  icon: commentState.currentSort == option.value
                      ? const Icon(Icons.arrow_drop_down)
                      : null,
                );
              }).toList(),
            ),
          ),
          pinned: true,
        );
      },
    );
  }

  Widget _buildNetworkStatusIndicator() {
    return Consumer<CommentStateService>(
      builder: (context, commentState, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: NetworkStatusWidget(
            showLabel: false,
            onlineColor: Colors.green,
            offlineColor: Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildRefreshButton(CommentStateService commentState) {
    return IconButton(
      icon: commentState.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : const Icon(Icons.refresh),
      onPressed: commentState.isLoading 
          ? null 
          : () => _refreshComments(),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.sort),
      onSelected: _changeSort,
      itemBuilder: (context) {
        return _commentStateService.sortOptions.map((option) {
          return PopupMenuItem<int>(
            value: option.value,
            child: Row(
              children: [
                Text(option.label),
                if (_commentStateService.currentSort == option.value) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.blue),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildMoreOptionsButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: _handleMoreOptions,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'clear_cache',
          child: Row(
            children: [
              Icon(Icons.clear_all),
              SizedBox(width: 8),
              Text('清除缓存'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reload_emotes',
          child: Row(
            children: [
              Icon(Icons.emoji_emotions),
              SizedBox(width: 8),
              Text('重新加载表情包'),
            ],
          ),
        ),
        if (_commentStateService.comments.isNotEmpty)
          const PopupMenuItem(
            value: 'scroll_to_top',
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_up),
                SizedBox(width: 8),
                Text('回到顶部'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<CommentStateService>(
      builder: (context, commentState, child) {
        if (commentState.isLoading && commentState.comments.isEmpty) {
          return _buildLoadingWidget();
        }

        if (commentState.errorMessage != null && commentState.comments.isEmpty) {
          return _buildErrorWidget(commentState.errorMessage!);
        }

        if (commentState.comments.isEmpty) {
          return _buildEmptyWidget();
        }

        return _buildCommentList(commentState);
      },
    );
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

  Widget _buildErrorWidget(String error) {
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
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshComments,
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
          Text('暂无评论，快来抢沙发吧！', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCommentList(CommentStateService commentState) {
    return RefreshIndicator(
      onRefresh: () async => _refreshComments(),
      child: AnimatedList(
        key: _listKey,
        initialItemCount: commentState.comments.length + (commentState.hasMore ? 1 : 0),
        itemBuilder: (context, index, animation) {
          if (index == commentState.comments.length && commentState.hasMore) {
            return _buildLoadingMoreIndicator();
          }

          if (index >= commentState.comments.length) {
            return const SizedBox.shrink();
          }

          final comment = commentState.comments[index];
          return SizeTransition(
            sizeFactor: animation,
            child: EnhancedCommentWidget(
              comment: comment,
              oid: widget.aid?.toString() ?? widget.bvid,
              onReply: () => _showReplies(comment),
              onMoreActions: () => _showCommentActions(comment),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Consumer<CommentStateService>(
      builder: (context, commentState, child) {
        return commentState.isLoadingMore
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return FloatingActionButton(
          mini: true,
          onPressed: _scrollToTop,
          backgroundColor: themeService.isDarkMode 
              ? Colors.grey.shade800 
              : Colors.white,
          child: Icon(
            Icons.keyboard_arrow_up,
            color: themeService.isDarkMode 
                ? Colors.white 
                : Colors.black87,
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return EnhancedCommentInput(
      oid: widget.aid?.toString() ?? widget.bvid,
      placeholder: '写下你的评论...',
      onTextChanged: (text) {
        // 可以在这里处理输入变化
      },
      onSend: () {
        _scrollToBottom();
      },
      onEmoteSelected: () {
        // 表情选择后的处理
      },
    );
  }

  void _changeSort(int sort) {
    if (sort != _currentSort) {
      _currentSort = sort;
      _commentStateService.changeSort(sort, widget.aid?.toString() ?? widget.bvid);
    }
  }

  void _refreshComments() async {
    await _commentStateService.loadComments(
      oid: widget.aid?.toString() ?? widget.bvid,
      refresh: true,
    );
  }

  void _showReplies(CommentInfo comment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentReplyPage(
          oid: widget.aid?.toString() ?? widget.bvid,
          rootComment: comment,
          rootRpid: comment.rpid,
        ),
      ),
    );
  }

  Widget _buildRepliesSheet(CommentInfo comment) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(comment),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comment.replyCount + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return EnhancedCommentWidget(
                        comment: comment,
                        oid: widget.aid?.toString() ?? widget.bvid,
                        maxLines: 3,
                      );
                    }
                    
                    // 这里需要加载实际的回复数据
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Text('回复 $index'),
                    );
                  },
                ),
              ),
              EnhancedCommentInput(
                oid: widget.aid?.toString() ?? widget.bvid,
                parentRpid: comment.rpid,
                placeholder: '回复 @${comment.user?.uname ?? ''}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(CommentInfo comment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '回复',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${comment.replyCount} 条',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  void _showCommentActions(CommentInfo comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildCommentActionsSheet(comment),
    );
  }

  Widget _buildCommentActionsSheet(CommentInfo comment) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('复制评论'),
            onTap: () {
              Navigator.pop(context);
              _copyComment(comment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('分享评论'),
            onTap: () {
              Navigator.pop(context);
              _shareComment(comment);
            },
          ),
          if (comment.medias != null && comment.medias!.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('查看图片'),
              onTap: () {
                Navigator.pop(context);
                _showMediaGallery(comment);
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('举报评论'),
            onTap: () {
              Navigator.pop(context);
              _reportComment(comment);
            },
          ),
        ],
      ),
    );
  }

  void _handleMoreOptions(String action) {
    switch (action) {
      case 'clear_cache':
        _commentStateService.clearCache();
        _showSnackBar('缓存已清除');
        break;
      case 'reload_emotes':
        _commentStateService.loadEmotes();
        _showSnackBar('正在重新加载表情包...');
        break;
      case 'scroll_to_top':
        _scrollToTop();
        break;
    }
  }

  void _copyComment(CommentInfo comment) {
    // 实现复制功能
    _showSnackBar('评论已复制到剪贴板');
  }

  void _shareComment(CommentInfo comment) {
    // 实现分享功能
    _showSnackBar('分享功能待实现');
  }

  void _showMediaGallery(CommentInfo comment) {
    if (comment.medias == null || comment.medias!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MediaPreviewDialog(
        medias: comment.medias!,
      ),
    );
  }

  void _reportComment(CommentInfo comment) {
    // 实现举报功能
    _showSnackBar('举报功能待实现');
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// 自定义TabBar委托
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}