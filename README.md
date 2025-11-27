# bili_ownx - Flutter 版 Bilimiao

基于 Flutter 重写的 Bilimiao 核心功能，支持视频搜索、播放和下载。

## 功能特性

### ✅ 核心功能
- 🔍 **视频搜索** - 关键词搜索，支持排序和筛选
- ▶️ **视频播放** - 基于 media_kit，支持 DASH 和多种格式
- 📥 **视频下载** - 本地下载，支持进度显示

### ✅ 增强功能
- 📜 **搜索历史** - 自动保存，快速访问
- ⏱️ **播放历史** - 自动记录进度，断点续播
- 🎨 **画质选择** - 多种画质选项（流畅~1080P60）
- 💬 **弹幕系统** - API 框架（UI 待完善）

## 快速开始

### 环境要求
- Flutter 3.24.0 或更高版本
- Dart 3.9.2 或更高版本
- Android SDK
- JDK 17

### 安装依赖
```bash
flutter pub get
```

### 运行应用
```bash
# Android
flutter run

# 指定设备
flutter devices
flutter run -d <device_id>
```

### 构建 APK
```bash
# Debug 版本
flutter build apk --debug

# Release 版本
flutter build apk --release
```

## GitHub Actions 自动构建

项目配置了 GitHub Actions 自动构建流程：
- ✅ 推送到主分支时自动构建
- ✅ 自动创建 GitHub Release
- ✅ APK 作为 Artifacts 保存30天

详见 [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md)

## 项目结构

```
lib/
├── api/              # API 封装
├── models/           # 数据模型
├── services/         # 业务服务
├── pages/            # UI 页面
└── main.dart         # 入口文件
```

## 技术栈

- **框架**: Flutter
- **网络**: dio
- **播放器**: media_kit
- **存储**: shared_preferences, path_provider
- **状态管理**: StatefulWidget

## 开发文档

- [实施计划](implementation_plan.md)
- [GitHub Actions 指南](GITHUB_ACTIONS.md)

## 许可证

本项目仅供学习交流使用。

## 致谢

本项目参考了 [bilimiao](https://github.com/10miaomiao/bilimiao2) 的 API 实现。
