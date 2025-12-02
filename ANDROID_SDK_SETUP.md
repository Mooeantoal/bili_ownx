# Android SDK 安装和配置指南

## 问题描述
构建失败是因为系统找不到Android SDK。错误信息：
```
Unable to locate an Android SDK.
```

## 解决方案

### 方案1：安装Android Studio（推荐）
1. 下载并安装 Android Studio：https://developer.android.com/studio
2. 安装完成后，启动Android Studio
3. 在Android Studio中安装Android SDK：
   - Tools → SDK Manager
   - 选择SDK Platforms标签
   - 勾选Android 13 (API level 33)或更高版本
   - 点击Apply安装

### 方案2：仅安装Android SDK命令行工具
1. 下载Command Line Tools：https://developer.android.com/studio#command-tools
2. 解压到 `C:\Android\Sdk` 目录
3. 设置环境变量：
   ```powershell
   $env:ANDROID_HOME = "C:\Android\Sdk"
   $env:ANDROID_SDK_ROOT = "C:\Android\Sdk"
   $env:Path += ";C:\Android\Sdk\cmdline-tools\latest\bin"
   $env:Path += ";C:\Android\Sdk\platform-tools"
   ```

### 方案3：使用Flutter内置SDK（临时方案）
Flutter自带了基本的Android构建工具，可以尝试：

```powershell
# 清理项目
flutter clean

# 重新获取依赖
flutter pub get

# 尝试构建
flutter build apk --debug
```

## 环境变量设置
安装Android SDK后，需要设置以下环境变量：

**PowerShell:**
```powershell
$env:ANDROID_HOME = "C:\Users\mj102\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\mj102\AppData\Local\Android\Sdk"
$env:Path += ";$env:ANDROID_HOME\platform-tools"
$env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"
```

**系统环境变量（永久设置）：**
1. 右键"此电脑" → 属性
2. 高级系统设置 → 环境变量
3. 新建系统变量：
   - `ANDROID_HOME`: `C:\Users\mj102\AppData\Local\Android\Sdk`
   - `ANDROID_SDK_ROOT`: `C:\Users\mj102\AppData\Local\Android\Sdk`
4. 编辑Path变量，添加：
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`

## 验证安装
安装完成后，运行以下命令验证：

```powershell
flutter doctor -v
```

应该看到：
```
[✓] Android toolchain - develop for Android devices
    Android SDK at C:\Users\mj102\AppData\Local\Android\Sdk
    Platform android-33, build-tools 33.0.0
    Java binary at: C:\Program Files\Android\Android Studio\jbr\bin\java
```

## 重新构建
设置完成后，重新运行构建：

```powershell
flutter build apk --debug
```

## 已修复的配置
当前项目中已经修复的配置：
- ✅ NDK版本已更新为 27.0.12077973
- ✅ R8/ProGuard优化已启用
- ✅ 代码压缩和资源压缩已配置

只需要安装Android SDK即可完成构建。