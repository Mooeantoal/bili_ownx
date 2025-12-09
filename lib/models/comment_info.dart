import '../utils/comment_utils.dart';

/// 评论信息模型
class CommentInfo {
  final String rpid; // 评论ID
  final String oid; // 视频ID
  final int type; // 类型，1表示视频
  final String mid; // 用户ID
  final String message; // 评论内容
  int like; // 点赞数
  final int dislike; // 踩数
  final int replyCount; // 回复数
  final int createTime; // 创建时间
  final UserInfo? user; // 用户信息
  final ContentInfo? content; // 内容信息（包含表情等）
  final ReplyControl? replyControl; // 回复控制信息
  final List<CommentInfo>? replies; // 热门回复
  bool isLiked; // 是否已点赞
  final bool isTop; // 是否置顶
  final bool isFloorTop; // 是否楼层置顶

  CommentInfo({
    required this.rpid,
    required this.oid,
    required this.type,
    required this.mid,
    required this.message,
    required this.like,
    required this.dislike,
    required this.replyCount,
    required this.createTime,
    this.user,
    this.content,
    this.replyControl,
    this.replies,
    this.isLiked = false,
    this.isTop = false,
    this.isFloorTop = false,
  });

  /// 获取格式化的时间显示
  String get formattedTime => CommentTimeFormatter.format(createTime);
  
  /// 获取完整的日期时间显示
  String get fullTime => CommentTimeFormatter.formatFull(createTime);
  
  /// 获取点赞数的格式化显示
  String get formattedLike {
    if (like >= 10000) {
      return '${(like / 10000).toStringAsFixed(1)}万';
    } else if (like >= 1000) {
      return '${(like / 1000).toStringAsFixed(1)}k';
    }
    return like.toString();
  }
  
  /// 获取回复数的格式化显示
  String get formattedReplyCount {
    if (replyCount >= 10000) {
      return '${(replyCount / 10000).toStringAsFixed(1)}万';
    } else if (replyCount >= 1000) {
      return '${(replyCount / 1000).toStringAsFixed(1)}k';
    }
    return replyCount.toString();
  }

  factory CommentInfo.fromJson(Map<String, dynamic> json) {
    // 根据proto定义，使用正确的字段名
    return CommentInfo(
      rpid: json['rpid']?.toString() ?? json['id']?.toString() ?? '',
      oid: json['oid']?.toString() ?? '',
      type: json['type'] ?? 1,
      mid: json['mid']?.toString() ?? '',
      message: json['content'] is Map 
          ? json['content']['message'] ?? '' 
          : json['message'] ?? '',
      like: json['like'] ?? 0,
      dislike: json['dislike'] ?? 0,
      replyCount: json['rcount'] ?? json['reply_count'] ?? json['count'] ?? 0,
      createTime: json['ctime'] ?? 0,
      user: json['member'] is Map 
          ? UserInfo.fromJson(json['member']) 
          : null,
      content: json['content'] is Map 
          ? ContentInfo.fromJson(json['content']) 
          : null,
      replyControl: json['reply_control'] is Map 
          ? ReplyControl.fromJson(json['reply_control']) 
          : null,
      replies: json['replies'] is List
          ? (json['replies'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CommentInfo.fromJson)
              .toList()
          : null,
      isLiked: json['action'] == 1,
      isTop: json['is_top'] == 1,
      isFloorTop: json['is_floor_top'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rpid': rpid,
      'oid': oid,
      'type': type,
      'mid': mid,
      'content': {
        'message': message,
        ...?content?.toJson(),
      },
      'like': like,
      'dislike': dislike,
      'rcount': replyCount,
      'ctime': createTime,
      'member': user?.toJson(),
      'reply_control': replyControl?.toJson(),
      'replies': replies?.map((e) => e.toJson()).toList(),
      'action': isLiked ? 1 : 0,
      'is_top': isTop ? 1 : 0,
      'is_floor_top': isFloorTop ? 1 : 0,
    };
  }
}

/// 用户信息
class UserInfo {
  final String mid; // 用户ID
  final String uname; // 用户名
  final String face; // 头像URL
  final int level; // 用户等级
  final String? official; // 认证信息
  final String? vipStatus; // VIP状态
  final Sign? sign; // 签名信息

  UserInfo({
    required this.mid,
    required this.uname,
    required this.face,
    required this.level,
    this.official,
    this.vipStatus,
    this.sign,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      mid: json['mid']?.toString() ?? '',
      uname: json['uname'] ?? '',
      face: json['face'] ?? '',
      level: json['level'] ?? 0,
      official: json['official'] is Map ? json['official']['title'] : null,
      vipStatus: json['vip'] is Map ? json['vip']['status']?.toString() : null,
      sign: json['sign'] is Map ? Sign.fromJson(json['sign']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'uname': uname,
      'face': face,
      'level': level,
      'official': official != null ? {'title': official} : null,
      'vip': vipStatus != null ? {'status': int.parse(vipStatus!)} : null,
      'sign': sign?.toJson(),
    };
  }
}

/// 用户签名
class Sign {
  final String url; // 签名链接
  final String text; // 签名文本

  Sign({required this.url, required this.text});

  factory Sign.fromJson(Map<String, dynamic> json) {
    return Sign(
      url: json['url'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'text': text,
    };
  }
}

/// 内容信息
class ContentInfo {
  final String message; // 原始消息
  final String? plat; // 平台
  final List<EmoteInfo>? emotes; // 表情信息
  final List<AtInfo>? ats; // @用户信息
  final List<JumpUrl>? jumpUrls; // 跳转链接
  final List<TopicInfo>? topics; // 话题信息

  ContentInfo({
    required this.message,
    this.plat,
    this.emotes,
    this.ats,
    this.jumpUrls,
    this.topics,
  });

  factory ContentInfo.fromJson(Map<String, dynamic> json) {
    return ContentInfo(
      message: json['message'] ?? '',
      plat: json['plat'],
      emotes: json['emote'] is Map
          ? (json['emote'] as Map)
              .entries
              .where((e) => e.value is Map<String, dynamic>)
              .map((e) => EmoteInfo.fromJson({
                'id': e.key,
                ...(e.value as Map<String, dynamic>),
              }))
              .toList()
          : null,
      ats: json['at_name_to_mid'] is Map
          ? (json['at_name_to_mid'] as Map)
              .entries
              .map((e) => AtInfo(name: e.key, mid: e.value.toString()))
              .toList()
          : null,
      jumpUrls: json['jump_url'] is Map
          ? (json['jump_url'] as Map)
              .entries
              .where((e) => e.value is Map<String, dynamic>)
              .map((e) => JumpUrl.fromJson({
                'id': e.key,
                ...(e.value as Map<String, dynamic>),
              }))
              .toList()
          : null,
      topics: json['topics'] is Map
          ? (json['topics'] as Map)
              .entries
              .where((e) => e.value is Map<String, dynamic>)
              .map((e) => TopicInfo.fromJson({
                'id': e.key,
                ...(e.value as Map<String, dynamic>),
              }))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'plat': plat,
      'emote': emotes?.map((e) => {e.id: e.toJson()}).toList(),
      'at_name_to_mid': ats?.map((e) => {e.name: e.mid}).toList(),
      'jump_url': jumpUrls?.map((e) => {e.id: e.toJson()}).toList(),
      'topics': topics?.map((e) => {e.id: e.toJson()}).toList(),
    };
  }
}

/// 表情信息
class EmoteInfo {
  final String id; // 表情ID
  final String text; // 表情文本
  final String url; // 表情图片URL
  final int size; // 表情大小

  EmoteInfo({
    required this.id,
    required this.text,
    required this.url,
    required this.size,
  });

  factory EmoteInfo.fromJson(Map<String, dynamic> json) {
    return EmoteInfo(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'url': url,
      'size': size,
    };
  }
}

/// @用户信息
class AtInfo {
  final String name; // 用户名
  final String mid; // 用户ID

  AtInfo({required this.name, required this.mid});

  factory AtInfo.fromJson(Map<String, dynamic> json) {
    return AtInfo(
      name: json['name'] ?? '',
      mid: json['mid']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mid': mid,
    };
  }
}

/// 跳转链接信息
class JumpUrl {
  final String id; // 链接ID
  final String title; // 链接标题
  final String url; // 链接地址
  final int prefix; // 前缀

  JumpUrl({
    required this.id,
    required this.title,
    required this.url,
    required this.prefix,
  });

  factory JumpUrl.fromJson(Map<String, dynamic> json) {
    return JumpUrl(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      prefix: json['prefix'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'prefix': prefix,
    };
  }
}

/// 话题信息
class TopicInfo {
  final String id; // 话题ID
  final String name; // 话题名称
  final String url; // 话题链接

  TopicInfo({
    required this.id,
    required this.name,
    required this.url,
  });

  factory TopicInfo.fromJson(Map<String, dynamic> json) {
    return TopicInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}

/// 回复控制信息
class ReplyControl {
  final bool isUpSelect; // 是否UP主精选
  final bool isGlobalTop; // 是否全局置顶
  final int maxLine; // 最大行数
  final int timeDesc; // 时间描述类型

  ReplyControl({
    required this.isUpSelect,
    required this.isGlobalTop,
    required this.maxLine,
    required this.timeDesc,
  });

  factory ReplyControl.fromJson(Map<String, dynamic> json) {
    return ReplyControl(
      isUpSelect: json['is_up_select'] is bool ? json['is_up_select'] : false,
      isGlobalTop: json['is_global_top'] is bool ? json['is_global_top'] : false,
      maxLine: json['max_line'] is int ? json['max_line'] : 0,
      timeDesc: json['time_desc'] is int ? json['time_desc'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_up_select': isUpSelect,
      'is_global_top': isGlobalTop,
      'max_line': maxLine,
      'time_desc': timeDesc,
    };
  }
}

/// 评论响应
class CommentResponse {
  final List<CommentInfo> comments; // 评论列表
  final int totalCount; // 总评论数
  final PageConfig? page; // 分页信息
  final UpperConfig? upper; // UP主信息

  CommentResponse({
    required this.comments,
    required this.totalCount,
    this.page,
    this.upper,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    // 根据proto定义，主要字段可能有不同的命名
    final replies = json['replies'] as List? ?? [];
    
    final comments = replies
        .whereType<Map<String, dynamic>>()
        .map(CommentInfo.fromJson)
        .toList();
    
    return CommentResponse(
      comments: comments,
      totalCount: json['total'] is int ? json['total'] : json['count'] ?? 0,
      page: json['page'] is Map ? PageConfig.fromJson(json['page']) : null,
      upper: json['upper'] is Map ? UpperConfig.fromJson(json['upper']) : null,
    );
  }
}

/// 分页配置
class PageConfig {
  final int count; // 当前页数量
  final int num; // 页码
  final int size; // 每页大小

  PageConfig({
    required this.count,
    required this.num,
    required this.size,
  });

  factory PageConfig.fromJson(Map<String, dynamic> json) {
    return PageConfig(
      count: json['count'] is int ? json['count'] : 0,
      num: json['num'] is int ? json['num'] : 0,
      size: json['size'] is int ? json['size'] : 0,
    );
  }
}

/// UP主信息
class UpperConfig {
  final String mid; // UP主ID
  final String name; // UP主名称
  final bool allowReply; // 允许回复

  UpperConfig({
    required this.mid,
    required this.name,
    required this.allowReply,
  });

  factory UpperConfig.fromJson(Map<String, dynamic> json) {
    return UpperConfig(
      mid: json['mid']?.toString() ?? '',
      name: json['name'] is String ? json['name'] : '',
      allowReply: json['allow_reply'] is bool ? json['allow_reply'] : false,
    );
  }
}

/// 回复响应
class CommentReplyResponse {
  final List<CommentInfo> replies; // 回复列表
  final int totalCount; // 总回复数
  final PageConfig? page; // 分页信息
  final Cursor? cursor; // 游标信息

  CommentReplyResponse({
    required this.replies,
    required this.totalCount,
    this.page,
    this.cursor,
  });

  factory CommentReplyResponse.fromJson(Map<String, dynamic> json) {
    return CommentReplyResponse(
      replies: (json['replies'] is List ? json['replies'] as List : [])
          .whereType<Map<String, dynamic>>()
          .map(CommentInfo.fromJson)
          .toList(),
      totalCount: json['count'] is int ? json['count'] : 0,
      page: json['page'] is Map ? PageConfig.fromJson(json['page']) : null,
      cursor: json['cursor'] is Map ? Cursor.fromJson(json['cursor']) : null,
    );
  }
}

/// 游标信息
class Cursor {
  final int allCount; // 全部数量
  final int isEnd; // 是否结束

  Cursor({
    required this.allCount,
    required this.isEnd,
  });

  factory Cursor.fromJson(Map<String, dynamic> json) {
    return Cursor(
      allCount: json['all_count'] is int ? json['all_count'] : 0,
      isEnd: json['is_end'] is int ? json['is_end'] : 0,
    );
  }
}