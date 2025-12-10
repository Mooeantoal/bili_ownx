# Android SDK Platform 35 路径修复 (最终版)

## 🔧 问题分析

GitHub Actions构建失败，错误信息：
```
Failed to find target with hash string 'android-35' in: /home/runner/work/bili_ownx/bili_ownx/android-sdk
```

**根本原因**：
- Android SDK Platform 35 安装在 `android-35-2/` 目录
- Gradle 期望在 `android-35/` 目录查找
- 这是 Android SDK 35 的已知问题

## 🛠️ 修复方案

### 步骤 1: 更新 CI 配置

在 `.github/workflows/ci.yml` 中添加路径修复步骤：

```yaml
- name: 修复 Android SDK Platform 35 路径
  run: |
    echo "检查 Android SDK Platform 35 安装路径..."
    ls -la $ANDROID_HOME/platforms/ | grep android-35 || true
    
    # 等待安装完成
    sleep 5
    
    # 修复Android 35安装路径问题
    if [ -d "$ANDROID_HOME/platforms/android-35-2" ]; then
      echo "发现 android-35-2 目录，正在重命名为 android-35..."
      mv "$ANDROID_HOME/platforms/android-35-2" "$ANDROID_HOME/platforms/android-35"
      echo "✅ 路径修复完成"
    elif [ -d "$ANDROID_HOME/platforms/android-35" ]; then
      echo "✅ android-35 目录已存在，无需修复"
    else
      echo "❌ 未发现 android-35 或 android-35-2 目录"
      ls -la $ANDROID_HOME/platforms/
    fi
    
    # 验证修复结果
    echo "验证 Android 35 安装..."
    ls -la $ANDROID_HOME/platforms/android-35 && echo "✅ Android 35 路径验证成功" || echo "❌ android-35 目录不存在"
```

### 步骤 2: 关键改进

1. **分离安装和修复**：将路径修复作为独立步骤
2. **增加等待时间**：确保 SDK 安装完成
3. **增强验证**：检查多种可能的情况
4. **详细日志**：提供完整的调试信息

## 📋 技术细节

### 问题背景
- **compileSdk**: 35
- **targetSdk**: 35  
- **依赖要求**: androidx.media3 需要 compileSdk 35+
- **路径问题**: SDK 安装在 `android-35-2/` 而非 `android-35/`

### 修复逻辑
```bash
# 情况 1: android-35-2 存在 → 重命名为 android-35
# 情况 2: android-35 已存在 → 无需操作  
# 情况 3: 都不存在 → 报错并显示目录列表
```

## 🚀 预期结果

修复后的构建流程：
1. ✅ 安装 Android SDK Platform 35
2. ✅ 检测并修复路径问题
3. ✅ 验证路径正确性
4. ✅ Gradle 找到正确的 SDK 目标
5. ✅ Flutter 构建成功

## 🔄 验证步骤

提交修复后检查：
```bash
git add .github/workflows/ci.yml
git commit -m "fix(ci): 分离Android SDK 35路径修复为独立步骤"
git push origin main
```

然后在 GitHub Actions 中查看构建日志，确认：
- [ ] `✅ 路径修复完成` 或 `✅ android-35 目录已存在`
- [ ] `✅ Android 35 路径验证成功`
- [ ] 没有 `Failed to find target with hash string 'android-35'` 错误

## 📝 相关文档

- `ANDROID_SDK_VERSION_FIX.md` - SDK 版本升级记录
- `ANDROID_35_PATH_FIX.md` - 路径修复初版
- `COMPILATION_ERROR_FIX.md` - 编译错误修复

---

**状态**: 🟡 待验证  
**最后更新**: 2025-12-10  
**优先级**: 🔴 高 - 阻塞CI/CD