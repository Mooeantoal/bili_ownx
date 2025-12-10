# Android SDK Platform 35路径修复报告

## 问题描述

GitHub Actions构建仍然失败，错误信息：
```
Failed to find target with hash string 'android-35' in: /home/runner/work/bili_ownx/bili_ownx/android-sdk
```

## 根本原因

Android SDK Platform 35安装在了错误的路径：
- **实际安装路径**: `android-sdk/platforms/android-35-2/`
- **Gradle期望路径**: `android-sdk/platforms/android-35/`

这是因为Android SDK工具链的变化，新版本有时会添加后缀（如-2）。

## 修复方案

### 1. 更新CI配置文件

**文件**: `.github/workflows/ci.yml`

**新增修复步骤**:
```bash
# 修复Android 35安装路径问题
if [ -d "$ANDROID_HOME/platforms/android-35-2" ]; then
  mv "$ANDROID_HOME/platforms/android-35-2" "$ANDROID_HOME/platforms/android-35"
fi

# 验证修复结果
ls -la $ANDROID_HOME/platforms/android-35 || true
```

### 2. 完整修复流程

1. **清理旧版本**: `rm -rf $ANDROID_HOME/platforms/android-35*`
2. **安装新版本**: `sdkmanager "platforms;android-35" "build-tools;35.0.0"`
3. **路径修复**: 将`android-35-2`重命名为`android-35`
4. **验证安装**: 确认路径正确

## 预期结果

- ✅ Gradle能够找到Android 35平台
- ✅ Flutter构建成功
- ✅ APK文件正常生成

## 技术细节

### 安装路径分析
```
$ANDROID_HOME/platforms/
├── android-34/          # 旧版本
├── android-35-2/         # 新安装的路径（错误）
└── android-35/            # 修复后的正确路径
```

### 验证命令
```bash
# 检查目录结构
ls -la $ANDROID_HOME/platforms/

# 验证Android 35可访问性
test -d "$ANDROID_HOME/platforms/android-35" && echo "✅ Android 35 found" || echo "❌ Android 35 missing"
```

## 注意事项

1. **向后兼容**: 保留android-34以防需要回退
2. **清理策略**: 使用通配符清理所有android-35变体
3. **验证步骤**: 安装后立即验证路径正确性

修复完成时间: 2025-12-10
影响范围: CI/CD流水线，Android SDK安装流程
预期修复效果: 解决Android 35路径映射问题