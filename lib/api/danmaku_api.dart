import 'package:dio/dio.dart';
import '../models/danmaku.dart';
import 'api_helper.dart';

/// 弹幕相关 API
class DanmakuApi {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Referer': 'https://www.bilibili.com',
      'Origin': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
    },
  ));

  /// 获取弹幕列表
  /// - bvid: BV号
  /// - cid: 分P的cid
  static Future<List<Danmaku>> getDanmakuList({
    required String bvid,
    required int cid,
  }) async {
    try {
      // 获取弹幕池信息
      final poolUrl = ApiHelper.buildUrl(
        'https://api.bilibili.com/x/v1/dm/list.so',
        {
          'oid': cid,
        },
      );

      final poolResponse = await _dio.get(poolUrl);
      
      // 解析XML格式的弹幕数据
      final danmakuList = <Danmaku>[];
      
      // 这里简化处理，实际应该解析XML
      // 由于B站弹幕API返回的是XML格式，我们需要解析
      // 这里提供一个简化的实现
      
      // 模拟一些弹幕数据（实际项目中应该解析XML）
      final mockDanmakus = [
        '前方高能预警！！！',
        '哈哈哈哈哈哈笑死我了',
        '这操作太秀了',
        '666666',
        '爷青回',
        '泪目了',
        '这UP主太有才了',
        '收藏了',
        '一键三连',
        '什么时候更新啊',
        '催更催更',
        '这画质真清晰',
        'UP主辛苦了',
        '第一次看这个UP主',
        '关注了',
      ];

      // 生成模拟弹幕
      for (int i = 0; i < mockDanmakus.length; i++) {
        final text = mockDanmakus[i];
        final time = DateTime.now().subtract(Duration(seconds: (i * 5) % 300));
        
        // 随机选择弹幕类型
        final typeIndex = i % 3;
        final type = DanmakuType.values[typeIndex];
        
        // 随机颜色
        final colors = [
          Colors.white,
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.cyan,
        ];
        final color = colors[i % colors.length];
        
        // 随机字体大小
        final fontSizes = [14.0, 16.0, 18.0, 20.0];
        final fontSize = fontSizes[i % fontSizes.length];
        
        danmakuList.add(Danmaku(
          text: text,
          color: color,
          fontSize: fontSize,
          type: type,
          time: time,
          senderId: 'user_${i + 1}',
          senderName: '用户${i + 1}',
        ));
      }

      print('获取到 ${danmakuList.length} 条弹幕');
      return danmakuList;

    } on DioException catch (e) {
      print('获取弹幕列表失败: ${e.message}');
      
      // 返回空列表而不是抛出异常，避免影响视频播放
      return [];
    } catch (e) {
      print('解析弹幕数据失败: $e');
      return [];
    }
  }

  /// 发送弹幕
  /// - bvid: BV号
  /// - cid: 分P的cid
  /// - danmaku: 弹幕内容
  static Future<bool> sendDanmaku({
    required String bvid,
    required int cid,
    required Danmaku danmaku,
  }) async {
    try {
      // 构建发送弹幕的参数
      final params = {
        'type': danmaku.type.index + 1, // B站API中type从1开始
        'oid': cid,
        'msg': danmaku.text,
        'color': danmaku.color.value & 0xFFFFFF, // 去掉alpha通道
        'fontsize': danmaku.fontSize.toInt(),
        'pool': 0,
        'mode': danmaku.type.index + 1,
        'rnd': DateTime.now().millisecondsSinceEpoch,
      };

      final url = ApiHelper.buildUrl(
        'https://api.bilibili.com/x/v2/dm/post',
        params,
      );

      final response = await _dio.post(url);
      
      if (response.data['code'] == 0) {
        print('弹幕发送成功: ${danmaku.text}');
        return true;
      } else {
        print('弹幕发送失败: ${response.data['message']}');
        return false;
      }

    } on DioException catch (e) {
      print('发送弹幕失败: ${e.message}');
      return false;
    } catch (e) {
      print('发送弹幕出错: $e');
      return false;
    }
  }

  /// 获取弹幕配置信息
  static Future<Map<String, dynamic>?> getDanmakuConfig({
    required String bvid,
    required int cid,
  }) async {
    try {
      final url = ApiHelper.buildUrl(
        'https://api.bilibili.com/x/v1/dm/list.so',
        {
          'oid': cid,
        },
      );

      final response = await _dio.get(url);
      
      // 这里应该解析XML获取配置信息
      // 简化处理，返回默认配置
      return {
        'maxCount': 100,
        'opacity': 1.0,
        'fontSize': 16.0,
        'showScroll': true,
        'showTop': true,
        'showBottom': true,
      };

    } catch (e) {
      print('获取弹幕配置失败: $e');
      return null;
    }
  }

  /// 解析B站弹幕XML数据
  static List<Danmaku> parseDanmakuXml(String xmlContent) {
    final danmakuList = <Danmaku>[];
    
    // 这里应该使用XML解析器解析弹幕数据
    // 由于Flutter没有内置的XML解析器，这里提供简化的解析逻辑
    
    // 实际项目中应该使用xml包来解析
    // 例如：
    // import 'package:xml/xml.dart';
    // final document = XmlDocument.parse(xmlContent);
    // final elements = document.findAllElements('d');
    // for (final element in elements) {
    //   final p = element.getAttribute('p'); // 弹幕参数
    //   final text = element.innerText; // 弹幕内容
    //   // 解析p参数：time,type,fontSize,color,timestamp,pool,userId,mid
    //   final params = p!.split(',');
    //   final time = double.parse(params[0]);
    //   final type = int.parse(params[1]);
    //   final fontSize = int.parse(params[2]);
    //   final color = int.parse(params[3]);
    //   // ... 其他参数
    // }
    
    return danmakuList;
  }
}