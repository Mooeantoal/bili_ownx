import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 下载服务
class DownloadService {
  static final Dio _dio = Dio();

  /// 下载视频
  /// - url: 视频地址
  /// - fileName: 文件名
  /// - onProgress: 下载进度回调 (已下载字节数, 总字节数)
  static Future<String?> downloadVideo({
    required String url,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // 获取下载目录
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      
      // 如果目录不存在则创建
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final savePath = '${downloadDir.path}/$fileName';

      // 下载文件
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received, total);
          }
        },
      );

      return savePath;
    } catch (e) {
      print('下载失败: $e');
      return null;
    }
  }

  /// 获取下载列表
  static Future<List<FileSystemEntity>> getDownloadedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');

      if (!await downloadDir.exists()) {
        return [];
      }

      return downloadDir.listSync();
    } catch (e) {
      print('获取下载列表失败: $e');
      return [];
    }
  }

  /// 删除下载的文件
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }
}
