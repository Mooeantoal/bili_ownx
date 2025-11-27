# GitHub Actions 自动构建配置指南

## 功能说明

这个 GitHub Actions 工作流会：
1. ✅ 在每次推送到 `main` 或 `master` 分支时自动触发
2. ✅ 在创建 Pull Request 时自动触发（仅构建，不发布）
3. ✅ 支持手动触发构建
4. ✅ 构建 Debug APK
5. ✅ 上传 APK 为 GitHub Artifact（保留30天）
6. ✅ 自动创建 GitHub Release（仅主分支推送时）

## 使用步骤

### 1. 初始化 Git 仓库（如果还没有）
```bash
cd d:\Downloads\Android应用开发\bili_ownx
git init
git add .
git commit -m "Initial commit"
```

### 2. 创建 GitHub 仓库并推送
```bash
# 在 GitHub 上创建新仓库后
git remote add origin https://github.com/你的用户名/bili_ownx.git
git branch -M main
git push -u origin main
```

### 3. 工作流将自动运行

推送代码后，GitHub Actions 会自动：
- 设置 Flutter 环境
- 安装依赖
- 构建 APK
- 上传构建产物

## 获取构建的 APK

### 方式1: GitHub Artifacts
1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择最新的工作流运行
4. 在页面底部的 `Artifacts` 部分下载 APK

### 方式2: GitHub Releases
1. 进入 GitHub 仓库
2. 点击右侧的 `Releases`
3. 下载最新的 debug 版本

## 手动触发构建

1. 进入 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `Build and Release APK` 工作流
4. 点击 `Run workflow` 按钮
5. 选择分支并点击运行

## 高级配置

### 修改 Flutter 版本
编辑 `.github/workflows/build.yml`:
```yaml
flutter-version: 'stable' # 使用最新稳定版
# 或
flutter-version: '3.24.0' # 指定版本
```

### 构建 Release 版本
将构建命令改为：
```yaml
run: flutter build apk --release
```

**注意**: Release 版本需要配置签名密钥。

### 配置签名（可选）

如果要构建 Release 版本，需要：
1. 生成密钥库文件
2. 在 GitHub 仓库设置中添加 Secrets
3. 修改工作流以使用密钥签名

详细步骤见 Flutter 官方文档。

## 故障排查

### 构建失败
- 检查 Actions 页面的错误日志
- 确保 `pubspec.yaml` 中的依赖版本正确
- 确保代码没有编译错误

### 无法创建 Release
- 确保仓库有 Release 权限
- 检查 `GITHUB_TOKEN` 权限设置

## 文件位置
- 工作流配置: `.github/workflows/build.yml`
- 构建输出: `build/app/outputs/flutter-apk/app-debug.apk`
