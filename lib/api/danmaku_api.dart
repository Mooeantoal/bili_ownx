import 'package:dio/dio.dart';

/// 弹幕 API
class DanmakuApi {
  static final Dio _dio = Dio();

  /// 获取弹幕列表
  /// - cid: 视频CID
  static Future<List<DanmakuItem>> getDanmaku(int cid) async {
    try {
      final url = 'https://api.bilibili.com/x/v1/dm/list.so?oid=$cid';
      
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      // 解析XML格式的弹幕数据
      // 注意：实际项目中需要使用 xml 包来解析
      // 这里仅提供框架
      return _parseDanmaku(response.data);
    } catch (e) {
      print('获取弹幕失败: $e');
      return [];
    }
  }

  /// 解析弹幕数据（简化版）
  static List<DanmakuItem> _parseDanmaku(dynamic data) {
    // TODO: 使用 xml 包解析
    // 弹幕格式: <d p="时间,模式,大小,颜色,时间戳,池,用户ID,弹幕ID">弹幕内容</d>
    return [];
  }
}

/// 弹幕项
class DanmakuItem {
  final double time; // 出现时间（秒）
  final int mode; // 模式（1:滚动 4:底部 5:顶部）
  final int fontSize; // 字体大小
  final int color; // 颜色
  final String content; // 内容

  DanmakuItem({
    required this.time,
    required this.mode,
    required this.fontSize,
    required this.color,
    required this.content,
  });
}
