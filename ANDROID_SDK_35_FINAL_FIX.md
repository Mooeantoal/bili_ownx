# Android SDK 35 路径修复指南

## 问题描述

在 GitHub Actions 构建过程中，Android SDK 平台安装为 `android-35-2`，但构建系统期望找到 `android-35`。这导致构建失败：

```
Failed to find target with hash string 'android-35' in: /home/runner/work/bili_ownx/bili_ownx/android-sdk
```

## 根本原因

Android SDK Manager 有时会安装带有版本后缀的平台（如 `android-35-2`），但 Gradle 和 Flutter 构建系统期望标准格式（`android-35`）。

## 修复方案

### 1. 自动修复（推荐）

项目现在包含自动修复步骤，在构建过程中会：

- 检测是否存在 `android-35-2` 但缺少 `android-35`
- 创建符号链接 `android-35 -> android-35-2`
- 验证修复结果

### 2. 手动修复

如果需要手动修复，可以使用提供的脚本：

**Linux/macOS:**
```bash
./fix_android_sdk.sh
```

**Windows:**
```cmd
fix_android_sdk.bat
```

### 3. 本地开发修复

在本地开发环境中，如果遇到此问题：

```bash
# 进入 SDK platforms 目录
cd $ANDROID_HOME/platforms

# 创建符号链接（如果 android-35-2 存在但 android-35 不存在）
ln -sf android-35-2 android-35

# 验证
ls -la | grep android-35
```

## 实现细节

### GitHub Actions 工作流修复

在 `.github/workflows/ci.yml` 中添加了新的步骤：

```yaml
- name: 修复 Android SDK 35 路径
  run: |
    echo "🔧 修复 Android SDK 35 路径问题..."
    
    # 检查是否存在 android-35-2 但缺少 android-35
    if [ -d "$ANDROID_HOME/platforms/android-35-2" ] && [ ! -d "$ANDROID_HOME/platforms/android-35" ]; then
      echo "发现 android-35-2，创建 android-35 符号链接..."
      ln -sf "$ANDROID_HOME/platforms/android-35-2" "$ANDROID_HOME/platforms/android-35"
      echo "✓ 成功创建 android-35 符号链接"
    elif [ -d "$ANDROID_HOME/platforms/android-35" ]; then
      echo "✓ android-35 已存在，无需修复"
    else
      echo "❌ 未找到 android-35 或 android-35-2"
      # 尝试重新安装
      sdkmanager "platforms;android-35" || echo "安装 android-35 失败"
    fi
```

### 修复脚本功能

两个修复脚本（`.sh` 和 `.bat`）提供相同功能：

1. **环境检测**：检查 Android SDK 安装路径
2. **平台检测**：列出已安装的 Android 平台
3. **智能修复**：
   - 如果存在 `android-35-2` 但缺少 `android-35`，创建符号链接
   - 如果 `android-35` 已存在，跳过修复
   - 如果都不存在，尝试安装 `android-35`
4. **验证**：确认修复成功
5. **构建工具检查**：确保 `build-tools 35.0.0` 可用

## 预防措施

1. **锁定 SDK 版本**：在构建配置中明确指定所需版本
2. **缓存优化**：确保 GitHub Actions 缓存正确存储 SDK 组件
3. **定期验证**：在构建流程中加入验证步骤

## 故障排除

### 符号链接失败

如果符号链接创建失败，脚本会尝试复制目录：

```bash
cp -r android-35-2 android-35
```

### Windows 权限问题

在 Windows 上，可能需要管理员权限来创建符号链接。脚本会自动降级到复制方案。

### 验证修复

运行修复后，应该看到：

```
✓ android-35 现在可用
路径: /path/to/sdk/platforms/android-35
```

## 相关文件

- `.github/workflows/ci.yml` - GitHub Actions 工作流
- `fix_android_sdk.sh` - Linux/macOS 修复脚本
- `fix_android_sdk.bat` - Windows 修复脚本
- `android/app/build.gradle.kts` - Android 构建配置

## 更新日志

- **2025-12-12**: 初始版本，解决 GitHub Actions 构建失败问题
- 添加自动修复步骤到 CI/CD 流程
- 提供跨平台手动修复脚本