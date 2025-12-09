import 'package:flutter_test/flutter_test.dart';
import 'package:bili_ownx/models/comment_info.dart';
import 'package:bili_ownx/utils/comment_utils.dart';
import 'package:bili_ownx/utils/json_parser.dart';

void main() {
  group('评论API测试', () {
    test('CommentResponse JSON解析测试', () {
      // 模拟API响应数据
      final mockResponse = {
        'replies': [
          {
            'rpid': '123456',
            'oid': '789012',
            'type': 1,
            'mid': '345678',
            'like': 10,
            'rcount': 2,
            'ctime': 1640995200,
            'message': '测试评论',
            'member': {
              'mid': '345678',
              'uname': '测试用户',
              'face': 'https://example.com/avatar.jpg',
              'level': 3,
            },
            'content': {
              'message': '测试评论',
            },
          }
        ],
        'total': 100,
      };

      try {
        final commentResponse = CommentResponse.fromJson(mockResponse);
        expect(commentResponse.comments.length, 1);
        expect(commentResponse.comments[0].message, '测试评论');
        expect(commentResponse.comments[0].user?.uname, '测试用户');
        expect(commentResponse.totalCount, 100);
        // print('✅ CommentResponse解析测试通过');
      } catch (e) {
        // print('❌ CommentResponse解析测试失败: $e');
        rethrow;
      }
    });

    test('CommentInfo空数据处理测试', () {
      try {
        // 测试空数据
        final emptyResponse = CommentResponse.fromJson({
          'replies': [],
          'total': 0,
        });
        expect(emptyResponse.comments.length, 0);
        expect(emptyResponse.totalCount, 0);
        // print('✅ 空数据处理测试通过');
      } catch (e) {
        // print('❌ 空数据处理测试失败: $e');
        rethrow;
      }
    });

    test('CommentInfo部分字段缺失测试', () {
      try {
        // 测试部分字段缺失的情况
        final partialResponse = CommentResponse.fromJson({
          'replies': [
            {
              'rpid': '123456',
              'message': '简化评论',
              // 缺少其他字段
            }
          ],
          'total': 1,
        });
        
        expect(partialResponse.comments.length, 1);
        expect(partialResponse.comments[0].message, '简化评论');
        expect(partialResponse.comments[0].rpid, '123456');
        // 缺失字段应该使用默认值
        expect(partialResponse.comments[0].like, 0);
        expect(partialResponse.comments[0].replyCount, 0);
        // print('✅ 部分字段缺失处理测试通过');
      } catch (e) {
        print('❌ 部分字段缺失处理测试失败: $e');
        rethrow;
      }
    });

    test('评论时间格式化测试', () {
      final now = DateTime.now();
      final testTimestamp = (now.millisecondsSinceEpoch / 1000).floor();
      
      final comment = CommentInfo(
        rpid: '123',
        oid: '456',
        type: 1,
        mid: '789',
        message: '测试评论',
        like: 5,
        dislike: 0,
        replyCount: 2,
        createTime: testTimestamp,
      );
      
      expect(comment.formattedTime, '刚刚');
      expect(comment.fullTime, isA<String>());
      print('✅ 时间格式化测试通过');
    });

    test('评论数字格式化测试', () {
      final comment1 = CommentInfo(
        rpid: '1',
        oid: '1',
        type: 1,
        mid: '1',
        message: '测试',
        like: 15000,
        dislike: 0,
        replyCount: 2500,
        createTime: 0,
      );
      
      final comment2 = CommentInfo(
        rpid: '2',
        oid: '2',
        type: 1,
        mid: '2',
        message: '测试',
        like: 500,
        dislike: 0,
        replyCount: 100,
        createTime: 0,
      );
      
      expect(comment1.formattedLike, '1.5万');
      expect(comment1.formattedReplyCount, '2.5k');
      expect(comment2.formattedLike, '500');
      expect(comment2.formattedReplyCount, '100');
      print('✅ 数字格式化测试通过');
    });
  });

  group('评论工具类测试', () {
    test('缓存功能测试', () {
      final mockResponse = CommentResponse(
        comments: [],
        totalCount: 0,
      );
      
      // 测试缓存存储
      CommentCache.put('test_key', mockResponse);
      final cached = CommentCache.get('test_key');
      expect(cached, isNotNull);
      expect(cached!.totalCount, 0);
      
      // 测试缓存清除
      CommentCache.clear();
      final cleared = CommentCache.get('test_key');
      expect(cleared, isNull);
      
      print('✅ 缓存功能测试通过');
    });

    test('时间格式化工具测试', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final oneDayAgo = now.subtract(Duration(days: 1));
      
      final nowTimestamp = (now.millisecondsSinceEpoch / 1000).floor();
      final oneHourAgoTimestamp = (oneHourAgo.millisecondsSinceEpoch / 1000).floor();
      final oneDayAgoTimestamp = (oneDayAgo.millisecondsSinceEpoch / 1000).floor();
      
      expect(CommentTimeFormatter.format(nowTimestamp), '刚刚');
      expect(CommentTimeFormatter.format(oneHourAgoTimestamp), '1小时前');
      expect(CommentTimeFormatter.format(oneDayAgoTimestamp), '1天前');
      
      print('✅ 时间格式化工具测试通过');
    });

    test('JSON解析工具测试', () {
      // 测试有效API响应
      final validResponse = {
        'code': 0,
        'message': 'success',
        'data': {'test': 'value'}
      };
      
      expect(JsonParser.isValidApiResponse(validResponse), true);
      expect(JsonParser.getInt(validResponse['code']), 0);
      expect(JsonParser.getApiMessage(validResponse), 'success');
      
      // 测试无效API响应
      final invalidResponse = {'error': 'invalid'};
      expect(JsonParser.isValidApiResponse(invalidResponse), false);
      
      print('✅ JSON解析工具测试通过');
    });

    test('评论排序枚举测试', () {
      expect(CommentSortType.hot.value, 3);
      expect(CommentSortType.hot.displayName, '热度');
      expect(CommentSortType.time.value, 2);
      expect(CommentSortType.time.displayName, '时间');
      
      final hotType = CommentSortType.fromValue(3);
      expect(hotType, CommentSortType.hot);
      
      final unknownType = CommentSortType.fromValue(999);
      expect(unknownType, CommentSortType.hot); // 默认返回热度排序
      
      print('✅ 评论排序枚举测试通过');
    });

    test('评论操作结果测试', () {
      final successResult = CommentOperationResult.success(message: '操作成功');
      expect(successResult.success, true);
      expect(successResult.message, '操作成功');
      
      final failureResult = CommentOperationResult.failure('操作失败');
      expect(failureResult.success, false);
      expect(failureResult.message, '操作失败');
      
      print('✅ 评论操作结果测试通过');
    });
  });
}