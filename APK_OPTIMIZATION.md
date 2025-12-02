# APK 优化指南

## 🎯 已启用的优化措施

### 1. 代码压缩和资源压缩
在 `android/app/build.gradle.kts` 中已启用：

```kotlin
buildTypes {
    release {
        // 启用代码压缩
        isMinifyEnabled = true
        // 启用资源压缩
        isShrinkResources = true
        
        // 启用 R8 优化
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### 2. ProGuard/R8 规则配置
创建了 `android/app/proguard-rules.pro` 文件，包含：
- Flutter 相关类的保护规则
- 网络库（Dio、OkHttp）的保护规则
- 媒体播放器（MediaKit）的保护规则
- 序列化库（Gson）的保护规则
- Android 系统类的保护规则
- 日志移除规则

### 3. ABI 分割
配置了按 CPU 架构分离 APK：

```kotlin
splits {
    abi {
        isEnable = true
        reset()
        include("arm64-v8a", "armeabi-v7a")
        isUniversalApk = false
    }
}
```

这将生成两个独立的 APK：
- `app-arm64-v8a-release.apk` - 适用于 64 位 ARM 设备（推荐）
- `app-armeabi-v7a-release.apk` - 适用于 32 位 ARM 设备

## 📦 构建命令

### 使用提供的脚本
```bash
# Windows
./build_optimized_apk.bat

# Linux/macOS
chmod +x build_optimized_apk.sh
./build_optimized_apk.sh
```

### 手动构建
```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建 release APK (所有架构)
flutter build apk --release

# 构建 App Bundle (推荐用于发布)
flutter build appbundle --release

# 构建特定架构的 APK
flutter build apk --release --target-platform android-arm64
flutter build apk --release --target-platform android-arm
```

## 📊 预期优化效果

启用这些优化措施后，APK 大小预计可以减少：

| 优化措施 | 预计减少幅度 |
|---------|-------------|
| 代码压缩 | 15-25% |
| 资源压缩 | 10-20% |
| ABI 分割 | 30-50% (单个 APK) |
| **总计** | **40-60%** |

## 🔍 验证优化效果

构建完成后，检查文件大小：

```bash
# 检查 APK 大小
ls -lh build/app/outputs/flutter-apk/app-*-release.apk

# 检查 App Bundle 大小
ls -lh build/app/outputs/bundle/release/app-release.aab
```

## ⚠️ 注意事项

### 1. 测试重要性
- 在启用代码压缩后，必须充分测试应用功能
- 某些反射调用可能被误删，需要添加 ProGuard 规则

### 2. 发布建议
- **Google Play**: 使用 App Bundle (.aab) 格式
- **其他渠道**: 使用 arm64-v8a 版本的 APK
- **兼容性**: 如需支持老设备，可同时提供 armeabi-v7a 版本

### 3. 签名配置
当前使用 debug 签名，发布时需要配置正式签名：

```kotlin
signingConfigs {
    release {
        storeFile file('your-keystore.jks')
        storePassword 'your-store-password'
        keyAlias 'your-key-alias'
        keyPassword 'your-key-password'
    }
}
```

## 🚀 进一步优化建议

### 1. 依赖优化
- 移除未使用的依赖包
- 使用更轻量级的替代库

### 2. 资源优化
- 使用向量图替代位图
- 压缩图片资源
- 移除未使用的资源文件

### 3. 代码优化
- 移除未使用的代码
- 使用 tree shaking 优化
- 优化导入语句

### 4. 动态功能模块
- 将非核心功能作为动态模块
- 按需加载功能模块

## 📞 问题排查

如果构建后出现运行时错误：

1. **检查 ProGuard 规则**：添加缺失的类保护规则
2. **查看日志**：使用 `adb logcat` 查看详细错误信息
3. **逐步测试**：先测试核心功能，再测试边缘功能

## 📈 监控优化效果

建议定期监控 APK 大小：
- 每次发布前检查大小变化
- 记录优化措施的效果
- 设置 APK 大小的预警阈值