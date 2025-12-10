import '../utils/comment_utils.dart';

/// 评论信息模型 - 参考BLVD项目完善
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
  
  // BLVD项目新增字段
  final int action; // 操作状态 0:无 1:点赞 2:反对
  final int attr; // 属性位
  final int assist; // 助攻数
  final int count; // 总计数（可能是回复计数）
  final int dialog; // 对话ID
  final int fansgrade; // 粉丝等级
  final String rpidStr; // 字符串格式的rpid
  final String parentStr; // 父评论rpid字符串
  final String rootStr; // 根评论rpid字符串
  final bool isUpSelect; // 是否UP主精选
  final String? location; // 地理位置
  final String? device; // 发布设备
  final List<MediaInfo>? medias; // 图片/视频等媒体内容

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
    // 新增字段默认值
    this.action = 0,
    this.attr = 0,
    this.assist = 0,
    this.count = 0,
    this.dialog = 0,
    this.fansgrade = 0,
    this.rpidStr = '',
    this.parentStr = '',
    this.rootStr = '',
    this.isUpSelect = false,
    this.location,
    this.device,
    this.medias,
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
    // 根据BLVD项目的数据结构完善解析
    final contentData = json['content'];
    String message = '';
    if (contentData is Map) {
      message = contentData['message'] ?? '';
    } else {
      message = json['message'] ?? '';
    }
    
    // 确保获取正确的层级关系字段
    final parent = json['parent'] ?? 0;
    final root = json['root'] ?? 0;
    final parentStr = json['parent_str']?.toString() ?? parent.toString();
    final rootStr = json['root_str']?.toString() ?? root.toString();
    
    return CommentInfo(
      rpid: json['rpid']?.toString() ?? json['id']?.toString() ?? '',
      rpidStr: json['rpid_str']?.toString() ?? json['rpid'].toString(),
      oid: json['oid']?.toString() ?? '',
      type: json['type'] ?? 1,
      mid: json['mid']?.toString() ?? '',
      message: message,
      like: json['like'] ?? 0,
      dislike: json['dislike'] ?? 0,
      replyCount: json['rcount'] ?? json['reply_count'] ?? json['count'] ?? 0,
      createTime: json['ctime'] ?? 0,
      action: json['action'] ?? 0,
      attr: json['attr'] ?? 0,
      assist: json['assist'] ?? 0,
      count: json['count'] ?? 0,
      dialog: json['dialog'] ?? 0,
      fansgrade: json['fansgrade'] ?? 0,
      parentStr: parentStr,
      rootStr: rootStr,
      user: json['member'] is Map 
          ? UserInfo.fromJson(json['member']) 
          : null,
      content: contentData is Map 
          ? ContentInfo.fromJson(contentData) 
          : null,
      replyControl: json['reply_control'] is Map 
          ? ReplyControl.fromJson(json['reply_control']) 
          : null,
      replies: json['replies'] is List
          ? (json['replies'] as List)
              .whereType<Map<String, dynamic>>()
              .map((replyJson) {
                // 确保子评论的父子关系正确
                final reply = CommentInfo.fromJson(replyJson);
                // 如果子评论没有正确的root，设置为当前评论的rpid
                if (reply.rootStr.isEmpty) {
                  return CommentInfo(
                    rpid: reply.rpid,
                    rpidStr: reply.rpidStr,
                    oid: reply.oid,
                    type: reply.type,
                    mid: reply.mid,
                    message: reply.message,
                    like: reply.like,
                    dislike: reply.dislike,
                    replyCount: reply.replyCount,
                    createTime: reply.createTime,
                    action: reply.action,
                    attr: reply.attr,
                    assist: reply.assist,
                    count: reply.count,
                    dialog: reply.dialog,
                    fansgrade: reply.fansgrade,
                    parentStr: reply.parentStr.isEmpty ? json['rpid'].toString() : reply.parentStr,
                    rootStr: reply.rootStr.isEmpty ? json['rpid'].toString() : reply.rootStr,
                    user: reply.user,
                    content: reply.content,
                    replyControl: reply.replyControl,
                    replies: reply.replies,
                    medias: reply.medias,
                    isLiked: reply.isLiked,
                    isTop: reply.isTop,
                    isFloorTop: reply.isFloorTop,
                    isUpSelect: reply.isUpSelect,
                    location: reply.location,
                    device: reply.device,
                  );
                }
                return reply;
              }).toList()
          : null,
      medias: json['medias'] is List
          ? (json['medias'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MediaInfo.fromJson)
              .toList()
          : null,
      isLiked: json['action'] == 1,
      isTop: json['is_top'] == 1,
      isFloorTop: json['is_floor_top'] == 1,
      isUpSelect: json['is_up_select'] == 1,
      location: json['location'],
      device: contentData is Map ? contentData['device'] : null,
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

/// 用户信息 - 参考BLVD项目完善
class UserInfo {
  final String mid; // 用户ID
  final String uname; // 用户名
  final String face; // 头像URL
  final int level; // 用户等级
  final OfficialInfo? official; // 认证信息
  final VipInfo? vip; // VIP信息
  final String? sign; // 个性签名
  final PendantInfo? pendant; // 头像挂件
  final NameplateInfo? nameplate; // 勋章
  final bool isSenior; // 是否硬核会员

  UserInfo({
    required this.mid,
    required this.uname,
    required this.face,
    required this.level,
    this.official,
    this.vip,
    this.sign,
    this.pendant,
    this.nameplate,
    this.isSenior = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      mid: json['mid']?.toString() ?? '',
      uname: json['uname'] ?? '',
      face: json['face'] ?? '',
      level: json['level'] ?? 0,
      official: json['official'] is Map 
          ? OfficialInfo.fromJson(json['official']) 
          : null,
      vip: json['vip'] is Map 
          ? VipInfo.fromJson(json['vip']) 
          : null,
      sign: json['sign'],
      pendant: json['pendant'] is Map 
          ? PendantInfo.fromJson(json['pendant']) 
          : null,
      nameplate: json['nameplate'] is Map 
          ? NameplateInfo.fromJson(json['nameplate']) 
          : null,
      isSenior: json['is_senior'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'uname': uname,
      'face': face,
      'level': level,
      'official': official?.toJson(),
      'vip': vip?.toJson(),
      'sign': sign,
      'pendant': pendant?.toJson(),
      'nameplate': nameplate?.toJson(),
      'is_senior': isSenior,
    };
  }
}

/// 认证信息
class OfficialInfo {
  final int role; // 认证角色
  final String title; // 认证标题
  final String desc; // 认证描述
  final int type; // 认证类型

  OfficialInfo({
    required this.role,
    required this.title,
    required this.desc,
    required this.type,
  });

  factory OfficialInfo.fromJson(Map<String, dynamic> json) {
    return OfficialInfo(
      role: json['role'] ?? 0,
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      type: json['type'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'title': title,
      'desc': desc,
      'type': type,
    };
  }
}

/// VIP信息
class VipInfo {
  final int type; // VIP类型
  final int status; // VIP状态
  final int dueDate; // 到期时间
  final int vipPayType; // 付费类型
  final String themeType; // 主题类型
  final VipLabel? label; // VIP标签

  VipInfo({
    required this.type,
    required this.status,
    required this.dueDate,
    required this.vipPayType,
    required this.themeType,
    this.label,
  });

  factory VipInfo.fromJson(Map<String, dynamic> json) {
    return VipInfo(
      type: json['type'] ?? 0,
      status: json['status'] ?? 0,
      dueDate: json['due_date'] ?? 0,
      vipPayType: json['vip_pay_type'] ?? 0,
      themeType: json['theme_type'] ?? '',
      label: json['label'] is Map 
          ? VipLabel.fromJson(json['label']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'due_date': dueDate,
      'vip_pay_type': vipPayType,
      'theme_type': themeType,
      'label': label?.toJson(),
    };
  }
}

/// VIP标签
class VipLabel {
  final String path; // 标签路径
  final String text; // 标签文本
  final String labelTheme; // 标签主题
  final String textColor; // 文字颜色
  final String bgColor; // 背景色
  final int borderColor; // 边框色

  VipLabel({
    required this.path,
    required this.text,
    required this.labelTheme,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  factory VipLabel.fromJson(Map<String, dynamic> json) {
    return VipLabel(
      path: json['path'] ?? '',
      text: json['text'] ?? '',
      labelTheme: json['label_theme'] ?? '',
      textColor: json['text_color'] ?? '',
      bgColor: json['bg_color'] ?? '',
      borderColor: json['border_color'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'text': text,
      'label_theme': labelTheme,
      'text_color': textColor,
      'bg_color': bgColor,
      'border_color': borderColor,
    };
  }
}

/// 头像挂件信息
class PendantInfo {
  final int pid; // 挂件ID
  final String name; // 挂件名称
  final String image; // 挂件图片
  final int expire; // 过期时间

  PendantInfo({
    required this.pid,
    required this.name,
    required this.image,
    required this.expire,
  });

  factory PendantInfo.fromJson(Map<String, dynamic> json) {
    return PendantInfo(
      pid: json['pid'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      expire: json['expire'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'name': name,
      'image': image,
      'expire': expire,
    };
  }
}

/// 勋章信息
class NameplateInfo {
  final int nid; // 勋章ID
  final String name; // 勋章名称
  final String image; // 勋章图片
  final String imageSmall; // 小图片
  final String level; // 等级
  final String condition; // 获得条件

  NameplateInfo({
    required this.nid,
    required this.name,
    required this.image,
    required this.imageSmall,
    required this.level,
    required this.condition,
  });

  factory NameplateInfo.fromJson(Map<String, dynamic> json) {
    return NameplateInfo(
      nid: json['nid'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      imageSmall: json['image_small'] ?? '',
      level: json['level'] ?? '',
      condition: json['condition'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nid': nid,
      'name': name,
      'image': image,
      'image_small': imageSmall,
      'level': level,
      'condition': condition,
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

/// 媒体信息（图片/视频等）
class MediaInfo {
  final String type; // 媒体类型 image/video
  final String url; // 媒体URL
  final int width; // 宽度
  final int height; // 高度
  final String? thumbnail; // 缩略图URL
  final String? description; // 描述
  final int size; // 文件大小

  MediaInfo({
    required this.type,
    required this.url,
    required this.width,
    required this.height,
    this.thumbnail,
    this.description,
    this.size = 0,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      thumbnail: json['thumbnail'],
      description: json['description'],
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'width': width,
      'height': height,
      'thumbnail': thumbnail,
      'description': description,
      'size': size,
    };
  }
}

/// 用户建议 - 用于@功能
class UserSuggestion {
  final String uid;
  final String name;
  final String avatar;

  UserSuggestion(this.uid, this.name, this.avatar);

  factory UserSuggestion.fromJson(Map<String, dynamic> json) {
    return UserSuggestion(
      json['uid']?.toString() ?? '',
      json['name'] ?? '',
      json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'avatar': avatar,
    };
  }
}

/// 表情包响应
class EmoteResponse {
  final List<EmotePackage> packages;
  final List<EmoteItem> emotes;
  final List<EmoteItem> stickies;

  EmoteResponse({
    required this.packages,
    required this.emotes,
    required this.stickies,
  });

  factory EmoteResponse.fromJson(Map<String, dynamic> json) {
    final packages = (json['packages'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EmotePackage.fromJson)
        .toList();

    final emotes = (json['emote'] as Map? ?? {})
        .values
        .whereType<Map<String, dynamic>>()
        .map(EmoteItem.fromJson)
        .toList();

    final stickies = (json['stickies'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EmoteItem.fromJson)
        .toList();

    return EmoteResponse(
      packages: packages,
      emotes: emotes,
      stickies: stickies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packages': packages.map((e) => e.toJson()).toList(),
      'emote': Map.fromEntries(emotes.map((e) => MapEntry(e.id, e.toJson()))),
      'stickies': stickies.map((e) => e.toJson()).toList(),
    };
  }
}

/// 表情包
class EmotePackage {
  final int id;
  final String text;
  final String url;
  final String msize;
  final List<EmoteItem> emotes;
  final int type;
  final bool active;
  final int attr;
  final String packageName;
  final int packageId;

  EmotePackage({
    required this.id,
    required this.text,
    required this.url,
    required this.msize,
    required this.emotes,
    required this.type,
    required this.active,
    required this.attr,
    required this.packageName,
    required this.packageId,
  });

  factory EmotePackage.fromJson(Map<String, dynamic> json) {
    final emotes = (json['emote'] as Map? ?? {})
        .values
        .whereType<Map<String, dynamic>>()
        .map(EmoteItem.fromJson)
        .toList();

    return EmotePackage(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      url: json['url'] ?? '',
      msize: json['msize'] ?? '',
      emotes: emotes,
      type: json['type'] ?? 0,
      active: json['active'] ?? false,
      attr: json['attr'] ?? 0,
      packageName: json['package_name'] ?? '',
      packageId: json['package_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'url': url,
      'msize': msize,
      'emote': Map.fromEntries(emotes.map((e) => MapEntry(e.id, e.toJson()))),
      'type': type,
      'active': active,
      'attr': attr,
      'package_name': packageName,
      'package_id': packageId,
    };
  }
}

/// 表情项
class EmoteItem {
  final String id;
  final String text;
  final String url;
  final int size;
  final int width;
  final int height;
  final String? mtime;
  final int type;
  final bool meta;

  EmoteItem({
    required this.id,
    required this.text,
    required this.url,
    required this.size,
    required this.width,
    required this.height,
    this.mtime,
    required this.type,
    required this.meta,
  });

  factory EmoteItem.fromJson(Map<String, dynamic> json) {
    return EmoteItem(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? 1,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      mtime: json['mtime'],
      type: json['type'] ?? 0,
      meta: json['meta'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'url': url,
      'size': size,
      'width': width,
      'height': height,
      'mtime': mtime,
      'type': type,
      'meta': meta,
    };
  }
}