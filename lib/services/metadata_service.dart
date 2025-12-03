import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_metadata.dart';
import '../models/video_info.dart';
import '../api/video_api.dart';

class MetadataService {
  static final MetadataService _instance = MetadataService._internal();
  factory MetadataService() => _instance;
  MetadataService._internal();

  late Box<VideoMetadata> _metadataBox;
  static const String _boxName = 'video_metadata';

  /// 初始化
  Future<void> initialize() async {
    // 注册适配器
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VideoMetadataAdapter());
    }
    
    // 打开数据库
    _metadataBox = await Hive.openBox<VideoMetadata>(_boxName);
  }

  /// 获取视频元数据
  VideoMetadata? getMetadata(String bvid) {
    return _metadataBox.get(bvid);
  }

  /// 保存视频元数据
  Future<void> saveMetadata(VideoMetadata metadata) async {
    await _metadataBox.put(metadata.bvid, metadata);
  }

  /// 从VideoInfo创建并保存元数据
  Future<VideoMetadata> saveFromVideoInfo(VideoInfo videoInfo) async {
    final metadata = VideoMetadata(
      bvid: videoInfo.bvid,
      title: videoInfo.title,
      cover: videoInfo.cover,
      author: videoInfo.author,
      description: videoInfo.description ?? '',
      tags: videoInfo.tags ?? [],
      publishDate: videoInfo.publishDate ?? DateTime.now(),
      viewCount: videoInfo.viewCount ?? 0,
      likeCount: videoInfo.likeCount ?? 0,
      coinCount: videoInfo.coinCount ?? 0,
      favoriteCount: videoInfo.favoriteCount ?? 0,
      shareCount: videoInfo.shareCount ?? 0,
      duration: videoInfo.duration ?? '',
      partCount: videoInfo.parts.length,
      cachedAt: DateTime.now(),
      categories: _extractCategories(videoInfo),
      isFavorite: false,
    );

    await saveMetadata(metadata);
    return metadata;
  }

  /// 从视频信息中提取分类
  List<String> _extractCategories(VideoInfo videoInfo) {
    final categories = <String>[];
    
    // 从标签中提取分类
    if (videoInfo.tags != null) {
      for (final tag in videoInfo.tags!) {
        if (tag.length <= 4) {  // 短标签通常是分类
          categories.add(tag);
        }
      }
    }
    
    // 从标题中推断分类
    final title = videoInfo.title.toLowerCase();
    if (title.contains('mad') || title.contains('amv')) {
      categories.add('MAD·AMV');
    } else if (title.contains('手书') || title.contains('手绘')) {
      categories.add('手书');
    } else if (title.contains('mmd')) {
      categories.add('MMD');
    } else if (title.contains('鬼畜')) {
      categories.add('鬼畜');
    } else if (title.contains('翻唱')) {
      categories.add('翻唱');
    } else if (title.contains('演奏')) {
      categories.add('演奏');
    } else if (title.contains('舞蹈')) {
      categories.add('舞蹈');
    } else if (title.contains('游戏')) {
      categories.add('游戏');
    } else if (title.contains('知识') || title.contains('科普')) {
      categories.add('知识');
    } else if (title.contains('美食')) {
      categories.add('美食');
    } else if (title.contains('萌宠')) {
      categories.add('萌宠');
    }
    
    return categories.toSet().toList();  // 去重
  }

  /// 获取所有元数据
  List<VideoMetadata> getAllMetadata() {
    return _metadataBox.values.toList();
  }

  /// 获取收藏的视频
  List<VideoMetadata> getFavoriteVideos() {
    return _metadataBox.values.where((metadata) => metadata.isFavorite).toList();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String bvid) async {
    final metadata = _metadataBox.get(bvid);
    if (metadata != null) {
      final updatedMetadata = metadata.copyWith(isFavorite: !metadata.isFavorite);
      await _metadataBox.put(bvid, updatedMetadata);
    }
  }

  /// 按分类获取视频
  List<VideoMetadata> getVideosByCategory(String category) {
    return _metadataBox.values
        .where((metadata) => metadata.categories.contains(category))
        .toList();
  }

  /// 获取所有分类
  List<String> getAllCategories() {
    final categories = <String>{};
    for (final metadata in _metadataBox.values) {
      categories.addAll(metadata.categories);
    }
    return categories.toList()..sort();
  }

  /// 搜索元数据
  List<VideoMetadata> searchMetadata(String query) {
    final lowerQuery = query.toLowerCase();
    return _metadataBox.values.where((metadata) {
      return metadata.title.toLowerCase().contains(lowerQuery) ||
             (metadata.author?.toLowerCase().contains(lowerQuery) ?? false) ||
             metadata.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
             metadata.categories.any((category) => category.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 删除元数据
  Future<void> deleteMetadata(String bvid) async {
    await _metadataBox.delete(bvid);
  }

  /// 清理过期的元数据（超过30天）
  Future<void> cleanupExpiredMetadata() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _metadataBox.entries) {
      final metadata = entry.value;
      final daysSinceCached = now.difference(metadata.cachedAt).inDays;
      
      if (daysSinceCached > 30 && !metadata.isFavorite) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      await _metadataBox.delete(key);
    }
  }

  /// 更新元数据统计信息
  Future<void> updateMetadataStats(String bvid, {
    int? viewCount,
    int? likeCount,
    int? coinCount,
    int? favoriteCount,
    int? shareCount,
  }) async {
    final metadata = _metadataBox.get(bvid);
    if (metadata != null) {
      final updatedMetadata = metadata.copyWith(
        viewCount: viewCount ?? metadata.viewCount,
        likeCount: likeCount ?? metadata.likeCount,
        coinCount: coinCount ?? metadata.coinCount,
        favoriteCount: favoriteCount ?? metadata.favoriteCount,
        shareCount: shareCount ?? metadata.shareCount,
      );
      await _metadataBox.put(bvid, updatedMetadata);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final total = _metadataBox.length;
    final favorites = _metadataBox.values.where((m) => m.isFavorite).length;
    final categories = getAllCategories().length;
    
    return {
      'totalVideos': total,
      'favoriteVideos': favorites,
      'totalCategories': categories,
    };
  }

  /// 导出元数据
  List<Map<String, dynamic>> exportMetadata() {
    return _metadataBox.values.map((metadata) => metadata.toJson()).toList();
  }

  /// 导入元数据
  Future<void> importMetadata(List<Map<String, dynamic>> data) async {
    for (final item in data) {
      try {
        final metadata = VideoMetadata.fromJson(item);
        await _metadataBox.put(metadata.bvid, metadata);
      } catch (e) {
        print('导入元数据失败: $e');
      }
    }
  }
}