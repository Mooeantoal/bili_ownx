import 'package:dio/dio.dart';
import '../api/video_api.dart';
import '../models/comment_info.dart';
import '../utils/error_handler.dart';
import '../utils/json_parser.dart';
import '../utils/comment_utils.dart';

/// 评论系统 API
class CommentApi {
  final Dio _dio;
  static const bool _enableDebug = false; // 生产环境设为false

  CommentApi({Dio? dio}) : _dio = dio ?? VideoApi.createDio();

  void _debugLog(String message) {
    if (_enableDebug) {
      print('CommentApi: $message');
    }
  }

  /// 获取视频评论列表
  /// [oid] 视频 avid
  /// [sort] 排序方式 0:热门 1:最新 2:最热 (改为2:时间 3:热度)
  /// [pageNum] 页码
  /// [pageSize] 每页数量
  /// [useCache] 是否使用缓存
  /// [retryConfig] 重试配置
  Future<CommentResponse> getVideoComments({
    required String oid,
    int sort = 3, // 默认按热度排序
    int pageNum = 1,
    int pageSize = 20,
    bool useCache = true,
    RetryConfig? retryConfig,
  }) async {
    try {
      // 检查缓存
      if (useCache && pageNum == 1) {
        final cacheKey = CommentCache.generateKey(oid, sort, pageNum);
        final cachedResponse = CommentCache.get(cacheKey);
        if (cachedResponse != null) {
          _debugLog('使用缓存数据');
          return cachedResponse;
        }
      }

      // 根据参考项目调整参数
      final params = {
        'type': CommentConfig.videoType.toString(),
        'oid': oid,
        'sort': sort.toString(),
        'pn': pageNum.toString(),
        'ps': pageSize.toString(),
        'plat': '2', // 2表示移动端
      };

      _debugLog('发送评论请求参数: $params');

      final response = await _executeWithRetry(
        () => _dio.get(
          'https://api.bilibili.com/x/v2/reply/main',
          queryParameters: params,
        ),
        retryConfig ?? RetryConfig.defaultConfig,
      );

      _debugLog('API响应状态码: ${response.statusCode}');
      _debugLog('API响应数据类型: ${response.data.runtimeType}');
      _debugLog('API响应内容: ${response.data}');

      // 使用JsonParser进行安全验证
      if (!JsonParser.isValidApiResponse(response.data)) {
        _debugLog('API响应格式验证失败');
        throw Exception('API响应格式无效');
      }
      
      if (JsonParser.getInt(response.data['code']) != 0) {
        _debugLog('API返回错误代码: ${response.data['code']}');
        throw Exception(JsonParser.getApiMessage(response.data, '获取评论失败'));
      }
      
      final data = JsonParser.getMap(response.data['data']);
      if (data != null) {
        _debugLog('数据解析成功，开始转换模型');
        final commentResponse = CommentResponse.fromJson(data);
        
        // 缓存结果
        if (useCache && pageNum == 1) {
          final cacheKey = CommentCache.generateKey(oid, sort, pageNum);
          CommentCache.put(cacheKey, commentResponse);
        }
        
        return commentResponse;
      } else {
        _debugLog('data字段为空或格式错误');
        // 处理无效数据的情况
        final emptyResponse = CommentResponse(
          comments: [],
          totalCount: 0,
        );
        
        // 缓存空结果（避免重复请求）
        if (useCache && pageNum == 1) {
          final cacheKey = CommentCache.generateKey(oid, sort, pageNum);
          CommentCache.put(cacheKey, emptyResponse);
        }
        
        return emptyResponse;
      }
    } catch (e) {
      _debugLog('获取评论时发生错误: $e');
      throw Exception('获取评论失败: ${ErrorHandler.getMessage(e)}');
    }
  }

  /// 执行带重试机制的请求
  Future<T> _executeWithRetry<T>(
    Future<T> Function() requestFunction,
    RetryConfig config,
  ) async {
    dynamic lastError;
    
    for (int attempt = 0; attempt <= config.maxRetries; attempt++) {
      try {
        return await requestFunction();
      } catch (e) {
        lastError = e;
        
        if (!config.shouldRetry(e, attempt)) {
          rethrow;
        }
        
        if (attempt < config.maxRetries) {
          final delay = config.getRetryDelay(attempt);
          _debugLog('请求失败，${delay.inSeconds}秒后重试 (${attempt + 1}/${config.maxRetries})');
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastError;
  }

  /// 清除评论缓存
  void clearCache() {
    CommentCache.clear();
  }

  /// 清除过期缓存
  void clearExpiredCache() {
    CommentCache.clearExpired();
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

      final response = await _executeWithRetry(
        () => _dio.get(
          'https://api.bilibili.com/x/v2/reply/main',
          queryParameters: params,
        ),
        retryConfig ?? RetryConfig.defaultConfig,
      );

      // 使用JsonParser进行安全验证
      if (!JsonParser.isValidApiResponse(response.data)) {
        throw Exception('API响应格式无效');
      }
      
      if (JsonParser.getInt(response.data['code']) != 0) {
        throw Exception(JsonParser.getApiMessage(response.data, '获取回复失败'));
      }
      
      final data = JsonParser.getMap(response.data['data']);
      if (data != null) {
        return CommentReplyResponse.fromJson(data);
      } else {
        // 处理无效数据的情况
        return CommentReplyResponse(
          replies: [],
          totalCount: 0,
        );
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

      // 使用JsonParser进行安全验证
      if (!JsonParser.isValidApiResponse(response.data)) {
        throw Exception('API响应格式无效');
      }
      
      if (JsonParser.getInt(response.data['code']) != 0) {
        throw Exception(JsonParser.getApiMessage(response.data, '发送评论失败'));
      }
      
      return JsonParser.getMap(response.data['data']) ?? {};
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

      // 使用JsonParser进行安全验证
      return JsonParser.isValidApiResponse(response.data) && 
             JsonParser.getInt(response.data['code']) == 0;
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

      // 使用JsonParser进行安全验证
      return JsonParser.isValidApiResponse(response.data) && 
             JsonParser.getInt(response.data['code']) == 0;
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

      // 使用JsonParser进行安全验证
      if (!JsonParser.isValidApiResponse(response.data)) {
        throw Exception('API响应格式无效');
      }
      
      if (JsonParser.getInt(response.data['code']) != 0) {
        throw Exception(JsonParser.getApiMessage(response.data, '获取表情包失败'));
      }
      
      return JsonParser.getMap(response.data['data']) ?? {};
    } catch (e) {
      throw Exception('获取表情包失败: ${ErrorHandler.getMessage(e)}');
    }
  }
}