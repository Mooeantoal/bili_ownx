# Android SDK 安装指南

## 问题诊断

当前项目遇到的主要问题是：
1. ❌ Android SDK 未安装或未正确配置
2. ❌ Flutter 无法找到 Android SDK 路径

## 解决方案

### 方案一：安装 Android Studio（推荐）

1. **下载 Android Studio**
   - 访问：https://developer.android.com/studio
   - 下载 Windows 版本（推荐.exe安装包）

2. **安装 Android Studio**
   ```bash
   # 运行下载的安装包
   # 选择 "Standard" 安装模式
   # 确保勾选 "Android Virtual Device" 选项
   ```

3. **配置 Android SDK**
   - 启动 Android Studio
   - 进入 Settings → Appearance & Behavior → System Settings → Android SDK
   - 确保安装了以下组件：
     - Android SDK Platform-Tools
     - Android SDK Build-Tools 34.0.0
     - Android 14 (API level 34)
     - Android 13 (API level 33)

4. **设置环境变量**
   ```powershell
   # 添加到系统环境变量
   [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Users\$env:USERNAME\AppData\Local\Android\Sdk', 'User')
   [System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools', 'User')
   ```

### 方案二：仅安装 Android SDK

1. **下载 Command Line Tools**
   - 访问：https://developer.android.com/studio#command-tools
   - 下载 "Command line tools only" for Windows

2. **安装步骤**
   ```powershell
   # 创建安装目录
   mkdir C:\Android\Sdk
   cd C:\Android\Sdk
   
   # 解压下载的文件到 cmdline-tools 目录
   # 创建目录结构
   mkdir cmdline-tools\latest
   move cmdline-tools\* cmdline-tools\latest\
   ```

3. **设置环境变量**
   ```powershell
   # 设置 ANDROID_HOME
   [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android\Sdk', 'User')
   [System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Android\Sdk\cmdline-tools\latest\bin;C:\Android\Sdk\platform-tools;C:\Android\Sdk\tools', 'User')
   ```

4. **安装必要组件**
   ```bash
   # 重新打开 PowerShell，然后运行：
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```

## 验证安装

### 1. 检查 Android SDK
```bash
adb version
```

### 2. 检查 Flutter
```bash
flutter doctor -v
```

### 3. 更新 local.properties
确保 `android/local.properties` 文件包含正确的路径：
```properties
flutter.sdk=D:\Downloads\Flutter
sdk.dir=C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk
```

## 常见问题解决

### 问题1：许可证未接受
```bash
flutter doctor --android-licenses
```

### 问题2：构建失败
```bash
# 清理并重新构建
flutter clean
flutter pub get
flutter build apk --debug
```

### 问题3：Gradle 错误
```bash
# 进入 Android 目录清理
cd android
./gradlew clean
cd ..
flutter build apk --debug
```

## 推荐配置

为了确保最佳兼容性，建议使用以下配置：

- **Android Studio**: 最新稳定版
- **Android SDK**: API Level 34 (Android 14)
- **Build Tools**: 34.0.0
- **Java**: JDK 17 (通过 Android Studio 管理)
- **Flutter**: 3.24.0 或更高版本

## 下一步

安装完成后：

1. 重启 IDE 和终端
2. 运行 `flutter doctor -v` 验证配置
3. 尝试构建项目：`flutter build apk --debug`
4. 如果仍有问题，检查 `android/local.properties` 文件路径是否正确

---

*如果按照此指南操作后仍有问题，请提供具体的错误信息以便进一步诊断。*