# Android 14-16 支持说明

## 🎯 概述

为 Android 14 (API 34)、Android 15 (API 35) 和 Android 16 (API 36) 提供了完整的权限和存储适配支持。

## 📱 权限适配

### Android 14 (API 34)
```xml
<!-- 通知权限 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Android 15 (API 35)
```xml
<!-- 部分访问媒体权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>
```

### Android 16 (API 36)
```xml
<!-- 预留权限，根据实际需要添加 -->
```

## 📁 下载路径策略

### Android 14+ 优先级

1. **系统 Downloads 目录** (推荐)
   ```
   /storage/emulated/0/Download/BiliOwnx/[BVID]/
   ```
   - 用户最容易访问
   - 符合系统设计规范
   - 支持系统媒体扫描

2. **自定义外部存储目录**
   ```
   /storage/emulated/0/biliownxdownloads/[BVID]/
   ```
   - 备选方案
   - 仍然易于访问

3. **内部存储** (备选)
   ```
   /data/data/com.example.bili_ownx/app_flutter/downloads/[BVID]/
   ```
   - 权限被拒绝时的备选方案

## 🔧 技术实现

### 1. 权限请求逻辑

```dart
Future<bool> _requestStoragePermission() async {
  final androidInfo = await _getAndroidInfo();
  final sdkInt = androidInfo['version.sdkInt'] as int? ?? 30;
  
  // Android 14+ 需要通知权限
  if (sdkInt >= 34) {
    await _requestNotificationPermission();
  }
  
  // Android 15+ 需要部分访问媒体权限
  if (sdkInt >= 35) {
    await _requestPartialMediaPermission();
  }
  
  // Android 13+ 使用媒体权限
  if (sdkInt >= 33) {
    return await _requestMediaPermissions();
  }
  
  // Android 10-12 使用传统存储权限
  if (sdkInt >= 29) {
    return await _requestLegacyStoragePermissions();
  }
  
  return await _requestBasicStoragePermission();
}
```

### 2. 目录选择策略

```dart
Future<Directory> _getDownloadDirectory() async {
  final androidInfo = await _getAndroidInfo();
  final sdkInt = androidInfo['version.sdkInt'] as int? ?? 30;
  
  // Android 14+ 优先使用系统 Downloads 目录
  if (sdkInt >= 34) {
    final downloadsDir = await _getAndroid14DownloadDirectory();
    if (downloadsDir != null) return downloadsDir;
  }
  
  // Android 10+ 使用外部存储
  if (sdkInt >= 29) {
    final externalDir = await _getModernAndroidDownloadDirectory();
    if (externalDir != null) return externalDir;
  }
  
  // 备选方案
  return await _getInternalDownloadDirectory();
}
```

## 🛡️ 安全性考虑

### 1. 权限最小化原则
- 只请求必要的权限
- 提供权限被拒绝的备选方案
- 不强制要求管理外部存储权限

### 2. 数据隔离
- 应用数据存储在专用目录
- 遵循 Android 存储最佳实践
- 支持应用卸载时数据清理

### 3. 用户隐私
- 不访问无关的媒体文件
- 只在用户授权的范围内操作
- 提供清晰的权限使用说明

## 🔄 兼容性矩阵

| Android 版本 | API 级别 | 权限模型 | 下载路径 | 状态 |
|-------------|-----------|----------|----------|------|
| Android 16 | 36 | 媒体权限 | /Download/BiliOwnx/ | ✅ 支持 |
| Android 15 | 35 | 媒体权限 | /Download/BiliOwnx/ | ✅ 支持 |
| Android 14 | 34 | 媒体权限 | /Download/BiliOwnx/ | ✅ 支持 |
| Android 13 | 33 | 媒体权限 | /biliownxdownloads/ | ✅ 支持 |
| Android 12 | 32 | 存储权限 | /biliownxdownloads/ | ✅ 支持 |
| Android 11 | 30 | 存储权限 | /biliownxdownloads/ | ✅ 支持 |
| Android 10 | 29 | 存储权限 | /biliownxdownloads/ | ✅ 支持 |
| Android 9 | 28 | 存储权限 | /Android/data/.../downloads/ | ✅ 支持 |

## 📋 用户体验

### 权限请求流程
1. **首次启动**: 自动检测 Android 版本
2. **权限请求**: 根据版本请求相应权限
3. **优雅降级**: 权限被拒绝时提供备选方案
4. **状态显示**: 在下载管理页面显示当前路径类型

### 路径访问便利性
- **Android 14+**: 用户可在系统 Downloads 应用中找到文件
- **Android 10-13**: 用户可在文件管理器中找到 biliownxdownloads 文件夹
- **Android 9-**: 需要通过应用内管理或文件管理器访问

## 🐛 常见问题

### Q: Android 14+ 为什么优先使用系统 Downloads 目录？
A: 
- 符合 Android 14+ 的设计规范
- 用户最容易找到和访问
- 支持系统的媒体扫描和索引

### Q: 权限被拒绝怎么办？
A: 
- 应用会自动回退到内部存储
- 用户仍可正常使用下载功能
- 可以在系统设置中手动授予权限

### Q: Android 15+ 的部分访问媒体权限是什么？
A: 
- 允许用户选择性地授予媒体访问权限
- 比全权访问更保护隐私
- 应用只能访问用户明确选择的媒体文件

## 🔮 未来展望

### Android 16+ 预留支持
- 已预留权限配置空间
- 可根据实际需求快速适配
- 保持向后兼容性

### 长期维护策略
- 持续关注 Android 权限模型变化
- 及时更新权限请求逻辑
- 保持多版本兼容性

---

**最后更新**: 2025-12-03  
**支持版本**: Android 9 - Android 16  
**测试覆盖**: API 28 - API 36