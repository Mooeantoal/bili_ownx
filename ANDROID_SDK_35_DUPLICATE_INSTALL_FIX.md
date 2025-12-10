# Android SDK 35 重复安装问题修复

## 🔍 问题分析

发现Android SDK Platform 35被重复安装，导致路径冲突：

### 时间线分析
1. **12:04:09** - 第一次安装成功，路径修复完成
2. **12:06:40** - 第二次安装，安装在 `android-35-2` 目录
3. **12:06:43** - Gradle构建失败，找不到 `android-35`

### 冲突原因
两个步骤同时安装Android SDK：
1. `android-actions/setup-android@v3` - 自动安装基础组件
2. `安装 Android SDK 组件` - 手动安装特定版本

## 🛠️ 修复方案

### 步骤 1: 移除自动安装
将 `android-actions/setup-android@v3` 替换为纯环境变量设置：

```yaml
- name: 手动设置 Android SDK 路径
  run: |
    echo "设置 Android SDK 环境变量..."
    echo "ANDROID_HOME=$PWD/android-sdk" >> $GITHUB_ENV
    echo "ANDROID_SDK_ROOT=$PWD/android-sdk" >> $GITHUB_ENV
    echo "$PWD/android-sdk/cmdline-tools/latest/bin" >> $GITHUB_PATH
```

### 步骤 2: 保留手动安装
只保留 `安装 Android SDK 组件` 步骤，确保：
- 安装 `platforms;android-35`
- 安装 `build-tools;35.0.0`
- 路径修复逻辑正常工作

## 📋 修复逻辑

```bash
# 1. 清理旧版本
rm -rf $ANDROID_HOME/platforms/android-35*

# 2. 安装指定版本
sdkmanager "platforms;android-35" "build-tools;35.0.0"

# 3. 路径修复
if [ -d "$ANDROID_HOME/platforms/android-35-2" ]; then
    mv "$ANDROID_HOME/platforms/android-35-2" "$ANDROID_HOME/platforms/android-35"
fi

# 4. 验证
ls -la $ANDROID_HOME/platforms/android-35
```

## 🎯 预期结果

修复后的流程：
1. ✅ 单一Android SDK安装源
2. ✅ 正确的SDK组件版本
3. ✅ 路径修复100%成功
4. ✅ Gradle找到正确的SDK目标
5. ✅ Flutter构建成功

## 🔄 验证步骤

提交后检查：
```bash
git add .github/workflows/ci.yml ANDROID_SDK_35_DUPLICATE_INSTALL_FIX.md
git commit -m "fix(ci): 移除Android SDK重复安装，保留单一手动安装"
git push origin main
```

在GitHub Actions中确认：
- [ ] 只有一次Android SDK安装
- [ ] `✅ Android 35 路径验证成功`
- [ ] 没有 `Failed to find target with hash string 'android-35'` 错误
- [ ] APK构建成功

## 📝 相关文档

- `ANDROID_SDK_35_PATH_FINAL_FIX.md` - 路径修复初版
- `ANDROID_SDK_VERSION_FIX.md` - SDK版本升级
- `COMPILATION_ERROR_FIX.md` - 编译错误修复

---

**状态**: 🟡 待验证  
**最后更新**: 2025-12-10  
**优先级**: 🔴 高 - 解决重复安装冲突