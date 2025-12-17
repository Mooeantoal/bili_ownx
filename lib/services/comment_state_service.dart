import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/comment_api.dart';
import '../models/comment_info.dart';
import '../services/network_service.dart';
import '../utils/comment_utils.dart';

/// 评论状态管理器 - 参考BLVD项目的ViewModel模式
class CommentStateService extends ChangeNotifier {
  final CommentApi _commentApi;
  final NetworkService _networkService;
  
  // 评论列表状态
  List<CommentInfo> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  
  // 评论排序状态
  int _currentSort = 3; // 3:热度排序
  final List<SortOption> _sortOptions = [
    SortOption(0, '最新'),
    SortOption(2, '最热'),
    SortOption(3, '热度'),
  ];
  
  // 表情包状态
  EmoteResponse? _emoteResponse;
  bool _isLoadingEmotes = false;
  Map<String, EmoteItem> _emoteCache = {};
  
  // 用户状态
  bool _isLoggedIn = false;
  String? _userMid;
  
  // 网络状态
  bool _isOnline = true;
  
  // 缓存管理
  final Map<String, List<CommentInfo>> _commentCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  // 预加载
  Timer? _preloadTimer;

  CommentStateService({
    CommentApi? commentApi,
    NetworkService? networkService,
  }) : _commentApi = commentApi ?? CommentApi(),
       _networkService = networkService ?? NetworkService() {
    _initializeState();
  }

  void _initializeState() {
    // 监听网络状态变化
    _networkService.addListener(_onNetworkStatusChanged);
    _isOnline = _networkService.isOnline;
    
    // 初始化表情包缓存
    _loadEmoteCache();
  }

  // Getters
  List<CommentInfo> get comments => List.unmodifiable(_comments);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  int get currentSort => _currentSort;
  List<SortOption> get sortOptions => List.unmodifiable(_sortOptions);
  EmoteResponse? get emoteResponse => _emoteResponse;
  bool get isLoadingEmotes => _isLoadingEmotes;
  Map<String, EmoteItem> get emoteCache => Map.unmodifiable(_emoteCache);
  bool get isLoggedIn => _isLoggedIn;
  String? get userMid => _userMid;
  bool get isOnline => _isOnline;

  /// 加载评论列表
  Future<void> loadComments({
    required String oid,
    bool refresh = false,
    int? sort,
  }) async {
    if (!_isOnline) {
      _setError('网络连接已断开');
      return;
    }

    final targetSort = sort ?? _currentSort;
    final cacheKey = _generateCacheKey(oid, targetSort);

    // 检查缓存
    if (!refresh && _commentCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        _comments = _commentCache[cacheKey]!;
        _hasMore = _comments.length >= 20;
        _notifyLoadingChange(false, refresh);
        notifyListeners();
        return;
      }
    }

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    }

    if (!_hasMore && !refresh) return;

    _notifyLoadingChange(true, refresh);

    try {
      final response = await _commentApi.getVideoComments(
        oid: oid,
        sort: targetSort,
        pageNum: _currentPage,
        pageSize: 20,
        useCache: refresh, // 只在刷新时使用缓存
      );

      if (refresh) {
        _comments = response.comments;
        _commentCache[cacheKey] = _comments;
        _cacheTimestamps[cacheKey] = DateTime.now();
      } else {
        _comments.addAll(response.comments);
      }

      _currentSort = targetSort;
      _hasMore = response.comments.length >= 20;
      _currentPage++;
      _errorMessage = null;

      // 预加载下一页
      if (_hasMore && _currentPage < 3) { // 限制预加载页数
        _schedulePreload(oid, targetSort);
      }

    } catch (e) {
      _setError('加载评论失败: ${e.toString()}');
    } finally {
      _notifyLoadingChange(false, false);
      notifyListeners();
    }
  }

  /// 加载更多评论
  Future<void> loadMoreComments(String oid) async {
    if (!_hasMore || _isLoadingMore || !_isOnline) return;
    
    await loadComments(oid: oid, refresh: false);
  }

  /// 加载表情包
  Future<void> loadEmotes() async {
    if (_isLoadingEmotes || !_isOnline) return;

    _isLoadingEmotes = true;
    notifyListeners();

    try {
      final response = await _commentApi.getEmoteList();
      _emoteResponse = response;
      
      // 构建表情缓存
      for (final package in response.packages) {
        for (final emote in package.emotes) {
          _emoteCache[emote.text] = emote;
        }
      }
      
      for (final emote in response.emotes) {
        _emoteCache[emote.text] = emote;
      }
      
      _saveEmoteCache();
      
    } catch (e) {
      debugPrint('加载表情包失败: $e');
    } finally {
      _isLoadingEmotes = false;
      notifyListeners();
    }
  }

  /// 加载评论回复列表
  Future<List<CommentInfo>> loadCommentReplies({
    required String oid,
    required String rootRpid,
    String? currentRpid, // 当前评论的rpid，用于调试
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    if (!_isOnline) {
      throw Exception('网络连接已断开');
    }

    try {
      print('CommentStateService加载回复: rootRpid=$rootRpid, currentRpid=$currentRpid');
      
      final response = await _commentApi.getCommentReplies(
        oid: oid,
        rpid: currentRpid ?? rootRpid,
        rootRpid: rootRpid, // 确保使用根评论ID
        pageNum: pageNum,
        pageSize: pageSize,
      );
      
      final repliesList = response['replies'] as List<dynamic>? ?? [];
      
      // 为每个回复设置正确的父子关系
      final replies = repliesList
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentInfo.fromJson(json))
          .where((reply) {
            // 过滤掉根评论本身，确保只显示二级评论
            if (reply.rpid == rootRpid) {
              print('过滤掉根评论: rpid=${reply.rpid}');
              return false;
            }
            return true;
          })
          .map((reply) {
            // 确保回复的root和parent字段正确设置
            print('处理回复: rpid=${reply.rpid}, parent=${reply.parentStr}, root=${reply.rootStr}');
            
            return CommentInfo(
              rpid: reply.rpid,
              rpidStr: reply.rpidStr,
              oid: reply.oid,
              type: reply.type,
              mid: reply.mid,
              message: reply.message,
              like: reply.like,
              dislike: reply.dislike,
              replyCount: reply.replyCount,
              createTime: reply.createTime,
              action: reply.action,
              attr: reply.attr,
              assist: reply.assist,
              count: reply.count,
              dialog: reply.dialog,
              fansgrade: reply.fansgrade,
              parentStr: reply.parentStr.isEmpty ? rootRpid : reply.parentStr,
              rootStr: reply.rootStr.isEmpty ? rootRpid : reply.rootStr,
              user: reply.user,
              content: reply.content,
              replyControl: reply.replyControl,
              replies: reply.replies,
              medias: reply.medias,
              isLiked: reply.isLiked,
              isTop: reply.isTop,
              isFloorTop: reply.isFloorTop,
              isUpSelect: reply.isUpSelect,
              location: reply.location,
              device: reply.device,
            );
          }).toList();
      
      return replies;
    } catch (e) {
      throw Exception('加载回复失败: ${e.toString()}');
    }
  }

  /// 发送评论
  Future<void> sendComment({
    required String oid,
    required String message,
    String? parentRpid,
    String? rootRpid,
  }) async {
    if (!_isOnline) {
      _setError('网络连接已断开');
      return;
    }

    try {
      await _commentApi.sendComment(
        message: message,
        oid: oid,
        parent: parentRpid,
        root: rootRpid,
      );
      
      // 发送成功后刷新评论列表
      await loadComments(oid: oid, refresh: true);
      
    } catch (e) {
      _setError('发送评论失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 点赞评论
  Future<void> toggleLike({
    required String oid,
    required CommentInfo comment,
  }) async {
    if (!_isOnline) return;

    final action = comment.isLiked ? 0 : 1;
    final originalLikeCount = comment.like;

    // 乐观更新UI
    comment.isLiked = !comment.isLiked;
    comment.like += action == 1 ? 1 : -1;
    notifyListeners();

    try {
      final success = await _commentApi.likeComment(
        oid: oid,
        rpid: comment.rpid,
        action: action,
      );

      if (!success) {
        // 回滚乐观更新
        comment.isLiked = !comment.isLiked;
        comment.like = originalLikeCount;
        notifyListeners();
        _setError('操作失败，请重试');
      }
    } catch (e) {
      // 回滚乐观更新
      comment.isLiked = !comment.isLiked;
      comment.like = originalLikeCount;
      notifyListeners();
      _setError('操作失败: ${e.toString()}');
    }
  }

  /// 更改排序方式
  Future<void> changeSort(int sort, String oid) async {
    if (sort == _currentSort) return;
    
    await loadComments(oid: oid, refresh: true, sort: sort);
  }

  /// 清除缓存
  void clearCache() {
    _commentCache.clear();
    _cacheTimestamps.clear();
    _commentApi.clearCache();
    notifyListeners();
  }

  /// 处理用户登录状态变化
  void updateUserStatus(bool isLoggedIn, String? userMid) {
    _isLoggedIn = isLoggedIn;
    _userMid = userMid;
    notifyListeners();
  }

  /// 网络状态变化处理
  void _onNetworkStatusChanged() {
    final wasOnline = _isOnline;
    _isOnline = _networkService.isOnline;
    
    if (!wasOnline && _isOnline && _comments.isEmpty) {
      // 网络恢复时重新加载
      loadComments(oid: ''); // 这里需要实际的oid
    }
    
    notifyListeners();
  }

  /// 生成缓存键
  String _generateCacheKey(String oid, int sort) {
    return '${oid}_$sort';
  }

  /// 设置错误状态
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 通知加载状态变化
  void _notifyLoadingChange(bool loading, bool isRefresh) {
    if (isRefresh) {
      _isLoading = loading;
    } else {
      _isLoadingMore = loading;
    }
  }

  /// 安排预加载
  void _schedulePreload(String oid, int sort) {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isOnline) {
        _commentApi.preloadNextPage(
          oid: oid,
          sort: sort,
          currentPage: _currentPage,
        );
      }
    });
  }

  /// 加载表情包缓存
  void _loadEmoteCache() {
    // 这里可以从本地存储加载表情包缓存
    // 实际项目中应该使用shared_preferences等持久化存储
  }

  /// 保存表情包缓存
  void _saveEmoteCache() {
    // 这里可以保存表情包缓存到本地存储
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkStatusChanged);
    _preloadTimer?.cancel();
    super.dispose();
  }
}

/// 排序选项
class SortOption {
  final int value;
  final String label;

  SortOption(this.value, this.label);
}