# Android 下载路径更新说明

## 🎯 更新内容

将 Android 系统的下载路径从内部存储更改为外部存储，方便用户访问下载的视频文件。

## 📁 新的下载路径

### 主要路径（Android）
```
/storage/emulated/0/biliownxdownloads/[BVID]/
├── 1_高清 1080P.mp4     # 视频文件
└── 1_audio.m4a          # 音频文件(如果有)
```

### 备选路径（权限被拒绝时）
```
/data/data/com.example.bili_ownx/app_flutter/downloads/[BVID]/
├── 1_高清 1080P.mp4
└── 1_audio.m4a
```

## 🔧 技术实现

### 1. 权限配置
在 `android/app/src/main/AndroidManifest.xml` 中添加了以下权限：

```xml
<!-- 基础存储权限 -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- Android 13+ 媒体权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<!-- 管理外部存储权限（Android 11+） -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### 2. 代码修改

#### 下载管理器更新
- 添加了 `_requestStoragePermission()` 方法请求权限
- 添加了 `_getDownloadDirectory()` 方法获取合适的下载目录
- 修改了下载任务的目录创建逻辑

#### 路径获取逻辑
```dart
Future<Directory> _getDownloadDirectory() async {
  if (Platform.isAndroid) {
    try {
      // 获取外部存储目录
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // 从 /storage/emulated/0/Android/data/package.name/files
        // 提取基础路径 /storage/emulated/0/
        final basePath = externalDir.path.split('Android')[0];
        final customDownloadDir = Directory('${basePath}biliownxdownloads');
        
        if (!await customDownloadDir.exists()) {
          await customDownloadDir.create(recursive: true);
        }
        
        return customDownloadDir;
      }
    } catch (e) {
      print('获取外部存储失败，使用内部存储: $e');
    }
    
    // 备选方案：使用内部存储
    final internalDir = await getApplicationDocumentsDirectory();
    return Directory('${internalDir.path}/downloads');
  } else {
    // 非 Android 平台使用应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/downloads');
  }
}
```

## 📱 用户体验改进

### 优势
1. **易于访问**: 用户可以在文件管理器中直接找到下载的视频
2. **大容量**: 外部存储通常有更多空间
3. **备份方便**: 可以轻松复制到其他设备或云存储
4. **兼容性好**: 与其他视频播放器兼容

### 权限处理
- 应用启动时自动请求所需权限
- 权限被拒绝时自动回退到内部存储
- 提供清晰的权限说明和错误处理

## 🔄 兼容性说明

### Android 版本支持
- **Android 10+**: 需要存储权限和管理外部存储权限
- **Android 11+**: 需要分区存储适配
- **Android 13+**: 需要媒体访问权限

### 备选方案
- 如果外部存储权限被拒绝，自动使用内部存储
- 内部存储路径：`/data/data/com.example.bili_ownx/app_flutter/downloads/`
- 用户仍可在应用内查看和管理下载任务

## 🛠️ 开发者注意事项

### 权限请求时机
- 在 `DownloadManager.initialize()` 中请求权限
- 使用 `permission_handler` 包处理权限
- 提供友好的权限被拒绝处理

### 路径处理
- 使用 `getExternalStorageDirectory()` 获取基础路径
- 通过字符串操作提取 `/storage/emulated/0/` 前缀
- 确保目录存在后再使用

### 错误处理
- 捕获权限请求异常
- 提供内部存储备选方案
- 在错误日志中记录路径选择过程

## 📋 测试要点

1. **权限测试**: 测试各种权限状态下的行为
2. **路径测试**: 确认文件保存到正确位置
3. **兼容性测试**: 在不同 Android 版本上测试
4. **回退测试**: 测试权限被拒绝时的备选方案

## 🎉 总结

这次更新显著改善了 Android 用户的下载体验，让下载的视频文件更容易访问和管理。同时保持了良好的向后兼容性和错误处理机制。

---

**更新日期**: 2025-12-03  
**影响版本**: 1.0.0+  
**平台**: Android