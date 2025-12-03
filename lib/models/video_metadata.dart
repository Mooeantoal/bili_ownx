import 'package:hive/hive.dart';

part 'video_metadata.g.dart';

@HiveType(typeId: 1)
class VideoMetadata extends HiveObject {
  @HiveField(0)
  final String bvid;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String cover;
  
  @HiveField(3)
  final String? author;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final List<String> tags;
  
  @HiveField(6)
  final DateTime publishDate;
  
  @HiveField(7)
  final int viewCount;
  
  @HiveField(8)
  final int likeCount;
  
  @HiveField(9)
  final int coinCount;
  
  @HiveField(10)
  final int favoriteCount;
  
  @HiveField(11)
  final int shareCount;
  
  @HiveField(12)
  final String duration;
  
  @HiveField(13)
  final int partCount;
  
  @HiveField(14)
  final DateTime cachedAt;
  
  @HiveField(15)
  final List<String> categories;  // 分类标签
  
  @HiveField(16)
  final bool isFavorite;  // 是否收藏

  VideoMetadata({
    required this.bvid,
    required this.title,
    required this.cover,
    this.author,
    this.description = '',
    this.tags = const [],
    required this.publishDate,
    this.viewCount = 0,
    this.likeCount = 0,
    this.coinCount = 0,
    this.favoriteCount = 0,
    this.shareCount = 0,
    this.duration = '',
    this.partCount = 1,
    required this.cachedAt,
    this.categories = const [],
    this.isFavorite = false,
  });

  /// 获取格式化的观看数量
  String get formattedViewCount {
    if (viewCount >= 100000000) {
      return '${(viewCount / 100000000).toStringAsFixed(1)}亿';
    } else if (viewCount >= 10000) {
      return '${(viewCount / 10000).toStringAsFixed(1)}万';
    } else {
      return viewCount.toString();
    }
  }

  /// 获取格式化的点赞数量
  String get formattedLikeCount {
    if (likeCount >= 100000000) {
      return '${(likeCount / 100000000).toStringAsFixed(1)}亿';
    } else if (likeCount >= 10000) {
      return '${(likeCount / 10000).toStringAsFixed(1)}万';
    } else {
      return likeCount.toString();
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'bvid': bvid,
      'title': title,
      'cover': cover,
      'author': author,
      'description': description,
      'tags': tags,
      'publishDate': publishDate.millisecondsSinceEpoch,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'coinCount': coinCount,
      'favoriteCount': favoriteCount,
      'shareCount': shareCount,
      'duration': duration,
      'partCount': partCount,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'categories': categories,
      'isFavorite': isFavorite,
    };
  }

  /// 从JSON创建
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      bvid: json['bvid'],
      title: json['title'],
      cover: json['cover'],
      author: json['author'],
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      publishDate: DateTime.fromMillisecondsSinceEpoch(json['publishDate']),
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      coinCount: json['coinCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      duration: json['duration'] ?? '',
      partCount: json['partCount'] ?? 1,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt']),
      categories: List<String>.from(json['categories'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// 创建副本
  VideoMetadata copyWith({
    String? bvid,
    String? title,
    String? cover,
    String? author,
    String? description,
    List<String>? tags,
    DateTime? publishDate,
    int? viewCount,
    int? likeCount,
    int? coinCount,
    int? favoriteCount,
    int? shareCount,
    String? duration,
    int? partCount,
    DateTime? cachedAt,
    List<String>? categories,
    bool? isFavorite,
  }) {
    return VideoMetadata(
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      author: author ?? this.author,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      publishDate: publishDate ?? this.publishDate,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      coinCount: coinCount ?? this.coinCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      shareCount: shareCount ?? this.shareCount,
      duration: duration ?? this.duration,
      partCount: partCount ?? this.partCount,
      cachedAt: cachedAt ?? this.cachedAt,
      categories: categories ?? this.categories,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}