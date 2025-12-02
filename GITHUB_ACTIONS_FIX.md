# GitHub Actions 工作流修复

## 问题描述

GitHub Actions 构建失败，出现以下错误：
1. `Warning: Unexpected input(s) 'continue-on-error', valid inputs are [...]`
2. `Warning: No files were found with the provided path: build/**/*.apk`

## 根本原因

1. **无效参数**: `actions/upload-artifact@v4` 不支持 `continue-on-error` 参数
2. **APK 文件路径不完整**: 由于启用了 ABI 拆分，APK 文件生成在更具体的目录中

## 修复内容

### 1. 移除无效参数
```yaml
# 之前 (错误)
continue-on-error: true

# 修复后
if-no-files-found: warn
```

### 2. 更新 APK 文件路径
```yaml
# 之前 (不完整)
path: |
  build/**/*.apk
  build/app/outputs/**/*.apk
  android/app/build/outputs/**/*.apk

# 修复后 (完整)
path: |
  build/**/*.apk
  build/app/outputs/**/*.apk
  android/app/build/outputs/**/*.apk
  android/app/build/outputs/apk/debug/**/*.apk  # 新增 ABI 拆分目录
```

### 3. 优化构建脚本
- 使用 `flutter build apk --debug` 而不是 Gradle 直接构建
- 添加更详细的文件查找逻辑
- 包含 ABI 拆分目录的检查

## ABI 拆分配置

项目启用了 ABI 拆分以减小 APK 大小：
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

这会生成以下 APK 文件：
- `app-arm64-v8a-debug.apk` (64位 ARM 设备)
- `app-armeabi-v7a-debug.apk` (32位 ARM 设备)

## 验证结果

✅ 移除了无效参数 `continue-on-error`
✅ 使用了正确的 `if-no-files-found: warn` 参数
✅ 包含了完整的 APK 文件路径，包括 ABI 拆分目录
✅ 工作流 YAML 语法正确

## 预期效果

修复后的工作流将：
1. 不再出现参数错误警告
2. 正确找到并上传所有生成的 APK 文件
3. 在 Release 中包含所有架构的 APK 文件
4. 即使没有找到 APK 文件也不会失败（只会警告）