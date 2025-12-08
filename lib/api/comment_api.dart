import 'package:dio/dio.dart';
import '../api/video_api.dart';
import '../models/comment_info.dart';
import '../utils/error_handler.dart';

/// 评论系统 API
class CommentApi {
  final Dio _dio;

  CommentApi({Dio? dio}) : _dio = dio ?? VideoApi.createDio();

  /// 获取视频评论列表
  /// [oid] 视频 avid
  /// [sort] 排序方式 0:热门 1:最新 2:最热
  /// [pageNum] 页码
  /// [pageSize] 每页数量
  Future<CommentResponse> getVideoComments({
    required String oid,
    int sort = 0,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = {
        'type': '1', // 1表示视频
        'oid': oid,
        'sort': sort.toString(),
        'pn': pageNum.toString(),
        'ps': pageSize.toString(),
        'plat': '2', // 2表示移动端
      };

      final response = await _dio.get(
        'https://api.bilibili.com/x/v2/reply/main',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return CommentResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '获取评论失败');
      }
    } catch (e) {
      throw Exception('获取评论失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 获取评论回复列表
  /// [oid] 视频 avid
  /// [rpid] 根评论 rpid
  /// [pageNum] 页码
  /// [pageSize] 每页数量
  Future<CommentReplyResponse> getCommentReplies({
    required String oid,
    required String rpid,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    try {
      final params = {
        'type': '1',
        'oid': oid,
        'root': rpid,
        'sort': '0',
        'pn': pageNum.toString(),
        'ps': pageSize.toString(),
      };

      final response = await _dio.get(
        'https://api.bilibili.com/x/v2/reply/main',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return CommentReplyResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '获取回复失败');
      }
    } catch (e) {
      throw Exception('获取回复失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 发送评论
  /// [message] 评论内容
  /// [oid] 视频 avid
  /// [root] 根评论 rpid（回复评论时使用）
  /// [parent] 父评论 rpid（回复评论时使用）
  Future<Map<String, dynamic>> sendComment({
    required String message,
    required String oid,
    String? root,
    String? parent,
  }) async {
    try {
      final params = {
        'type': '1',
        'oid': oid,
        'message': message,
        'plat': '2',
      };

      if (root != null) params['root'] = root;
      if (parent != null) params['parent'] = parent;

      final response = await _dio.post(
        'https://api.bilibili.com/x/v2/reply/add',
        data: params,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? '发送评论失败');
      }
    } catch (e) {
      throw Exception('发送评论失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 点赞/取消点赞评论
  /// [oid] 视频 avid
  /// [rpid] 评论 rpid
  /// [action] 0:取消赞 1:点赞
  Future<bool> likeComment({
    required String oid,
    required String rpid,
    required int action,
  }) async {
    try {
      final params = {
        'type': '1',
        'oid': oid,
        'rpid': rpid,
        'action': action.toString(),
      };

      final response = await _dio.post(
        'https://api.bilibili.com/x/v2/reply/action',
        data: params,
      );

      return response.statusCode == 200 && response.data['code'] == 0;
    } catch (e) {
      throw Exception('点赞失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 删除评论
  /// [oid] 视频 avid
  /// [rpid] 评论 rpid
  Future<bool> deleteComment({
    required String oid,
    required String rpid,
  }) async {
    try {
      final params = {
        'type': '1',
        'oid': oid,
        'rpid': rpid,
      };

      final response = await _dio.post(
        'https://api.bilibili.com/x/v2/reply/del',
        data: params,
      );

      return response.statusCode == 200 && response.data['code'] == 0;
    } catch (e) {
      throw Exception('删除评论失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 获取表情包列表
  Future<Map<String, dynamic>> getEmoteList() async {
    try {
      final response = await _dio.get(
        'https://api.bilibili.com/x/emote/user/panel',
        queryParameters: {
          'business': 'reply',
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? '获取表情包失败');
      }
    } catch (e) {
      throw Exception('获取表情包失败: ${ErrorHandler.getMessage(e)}');
    }
  }
}