# Flutter 重写 BLVD 核心功能实施计划

## 1. 项目概述
本项目 `bili_ownx` 旨在用 Flutter 重新实现 `bilimiao` (BLVD) 的核心功能：
- 视频搜索
- 视频播放
- 视频下载

## 2. 技术栈选择
- **语言**: Dart
- **框架**: Flutter
- **网络请求**: `dio`
- **加密**: `crypto` (用于 API 签名)
- **视频播放**: `media_kit` (支持多种格式和流媒体，性能优异)
- **状态管理**: `provider` 或 `flutter_riverpod` (本示例使用简单的 `ChangeNotifier` 或 `setState` 以保持简洁)
- **本地存储/下载**: `path_provider`, `permission_handler`

## 3. 关键实现细节

### 3.1 API 签名 (ApiHelper)
Bilibili API 需要对参数进行签名。逻辑如下：
1.  收集所有参数（包括默认参数如 `appkey`, `ts` 等）。
2.  按参数名 ASCII 码排序。
3.  拼接成 URL 查询字符串格式 (`key1=value1&key2=value2`)。
4.  在末尾拼接 `AppSecret`。
5.  计算 MD5 值作为 `sign` 参数。

**AppKey / Secret (参考 BLVD):**
- Key: `dfca71928277209b`
- Secret: `b5475a8825547a4fc26c7d518eaaa02e`

### 3.2 搜索功能
- **接口**: `https://app.bilibili.com/x/v2/search`
- **参数**: `keyword`, `pn` (页码), `ps` (页大小), `order` (排序) 等。

### 3.3 视频播放
- **获取播放地址**: 需要调用 `https://api.bilibili.com/x/player/playurl`。
- **参数**: `avid`/`bvid`, `cid`, `qn` (画质)。
- **播放器**: 使用 `media_kit`。它基于原生 MPV，支持 DASH 流（视频音频分离），这对于 B 站高画质视频非常重要。

### 3.4 视频下载
- 使用 `dio.download` 下载视频流。
- 如果是 DASH 格式（音视频分离），需要分别下载 `.m4s` 文件。
- 简单的实现可以只下载 MP4 格式（如果 API 提供）或 FLV。

## 4. 目录结构
```
lib/
├── api/
│   ├── api_helper.dart      # 签名和请求封装
│   ├── search_api.dart      # 搜索相关 API
│   └── video_api.dart       # 视频详情和播放地址 API
├── models/
│   ├── search_result.dart   # 搜索结果模型
│   └── video_info.dart      # 视频信息模型
├── pages/
│   ├── home_page.dart       # 主页（搜索入口）
│   ├── search_page.dart     # 搜索结果页
│   └── player_page.dart     # 播放页
└── main.dart
```

## 5. 下一步行动
1.  添加依赖到 `pubspec.yaml`。
2.  实现 `ApiHelper`。
3.  实现搜索 UI 和逻辑。
4.  实现播放 UI 和逻辑。
