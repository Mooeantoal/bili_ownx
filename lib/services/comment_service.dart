import 'package:shared_preferences/shared_preferences.dart';
import '../models/comment_info.dart';

/// 评论服务
/// 用于管理评论缓存、设置等
class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存评论排序偏好
  Future<void> saveCommentSortPreference(int sort) async {
    await _prefs?.setInt('comment_sort', sort);
  }

  /// 获取评论排序偏好
  int getCommentSortPreference() {
    return _prefs?.getInt('comment_sort') ?? 0; // 默认热门排序
  }

  /// 保存评论草稿
  Future<void> saveCommentDraft(String videoId, String content) async {
    await _prefs?.setString('comment_draft_$videoId', content);
  }

  /// 获取评论草稿
  String? getCommentDraft(String videoId) {
    return _prefs?.getString('comment_draft_$videoId');
  }

  /// 删除评论草稿
  Future<void> removeCommentDraft(String videoId) async {
    await _prefs?.remove('comment_draft_$videoId');
  }

  /// 保存已点赞的评论列表
  Future<void> saveLikedComment(String commentId, bool isLiked) async {
    final likedComments = getLikedComments();
    if (isLiked) {
      likedComments.add(commentId);
    } else {
      likedComments.remove(commentId);
    }
    await _prefs?.setStringList('liked_comments', likedComments);
  }

  /// 获取已点赞的评论列表
  Set<String> getLikedComments() {
    final likedList = _prefs?.getStringList('liked_comments') ?? [];
    return Set<String>.from(likedList);
  }

  /// 检查评论是否已点赞
  bool isCommentLiked(String commentId) {
    return getLikedComments().contains(commentId);
  }

  /// 保存已屏蔽的用户
  Future<void> saveBlockedUser(String mid) async {
    final blockedUsers = getBlockedUsers();
    blockedUsers.add(mid);
    await _prefs?.setStringList('blocked_users', blockedUsers.toList());
  }

  /// 获取已屏蔽的用户列表
  Set<String> getBlockedUsers() {
    final blockedList = _prefs?.getStringList('blocked_users') ?? [];
    return Set<String>.from(blockedList);
  }

  /// 移除屏蔽的用户
  Future<void> removeBlockedUser(String mid) async {
    final blockedUsers = getBlockedUsers();
    blockedUsers.remove(mid);
    await _prefs?.setStringList('blocked_users', blockedUsers.toList());
  }

  /// 检查用户是否被屏蔽
  bool isUserBlocked(String mid) {
    return getBlockedUsers().contains(mid);
  }

  /// 保存屏蔽的关键字
  Future<void> saveBlockedKeyword(String keyword) async {
    final blockedKeywords = getBlockedKeywords();
    blockedKeywords.add(keyword);
    await _prefs?.setStringList('blocked_keywords', blockedKeywords.toList());
  }

  /// 获取屏蔽的关键字列表
  Set<String> getBlockedKeywords() {
    final keywordList = _prefs?.getStringList('blocked_keywords') ?? [];
    return Set<String>.from(keywordList);
  }

  /// 移除屏蔽的关键字
  Future<void> removeBlockedKeyword(String keyword) async {
    final blockedKeywords = getBlockedKeywords();
    blockedKeywords.remove(keyword);
    await _prefs?.setStringList('blocked_keywords', blockedKeywords.toList());
  }

  /// 过滤评论内容（屏蔽关键字）
  List<CommentInfo> filterComments(List<CommentInfo> comments) {
    final blockedUsers = getBlockedUsers();
    final blockedKeywords = getBlockedKeywords();
    
    return comments.where((comment) {
      // 过滤被屏蔽的用户
      if (blockedUsers.contains(comment.mid)) {
        return false;
      }
      
      // 过滤包含屏蔽关键字的评论
      for (final keyword in blockedKeywords) {
        if (comment.message.toLowerCase().contains(keyword.toLowerCase())) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// 清理所有评论相关数据
  Future<void> clearAllCommentData() async {
    await _prefs?.remove('liked_comments');
    await _prefs?.remove('blocked_users');
    await _prefs?.remove('blocked_keywords');
    // 清理所有评论草稿
    final keys = _prefs?.getKeys() ?? [];
    for (final key in keys) {
      if (key.startsWith('comment_draft_')) {
        await _prefs?.remove(key);
      }
    }
  }
}