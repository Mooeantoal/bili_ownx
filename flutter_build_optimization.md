# Flutter构建优化配置指南

## 🚀 构建缓存优化已完成

### 1. Gradle构建优化 ✅
- **内存优化**: JVM堆内存调整为6GB (适配16GB内存系统)
- **并行构建**: 启用多模块并行编译
- **增量编译**: Java和Kotlin增量编译启用
- **构建缓存**: 本地Gradle缓存配置
- **VFS监控**: 文件系统监控优化

### 2. Android构建优化 ✅
- **R8优化**: 代码压缩和资源优化
- **依赖版本锁定**: 避免版本冲突导致的重复解析
- **编译器优化**: 预编译和缓存优化
- **包冲突解决**: 排除冲突的依赖

### 3. Flutter特定优化 ✅
- **预编译缓存**: Dart编译器缓存
- **增量编译**: 只重新编译修改的文件
- **资源优化**: 图片和资源缓存

## 📁 缓存目录说明

```
bili_ownx/
├── .gradle/                 # Gradle构建缓存
│   └── build-cache/         # 本地构建缓存
├── build/                   # Flutter构建缓存
├── .dart_tool/             # Dart工具缓存
└── .flutter-build-cache     # 自定义缓存配置
```

## ⚡ 额外优化建议

### 开发环境优化
```bash
# 1. 清理并重建缓存
flutter clean
cd android
./gradlew clean
./gradlew build --build-cache

# 2. 启用并行构建
flutter build apk --debug --no-pub --target-platform android-arm64

# 3. 预热构建环境
flutter packages get --no-precompile
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 生产构建优化
```bash
# 快速构建 (使用缓存)
flutter build apk --release --no-pub --target-platform android-arm64

# 包含所有架构
flutter build apk --release --no-pub --split-per-abi
```

## 🔧 环境变量优化 (可选)

在系统环境变量中添加:
```bash
# Gradle优化
export GRADLE_OPTS="-Xmx6G -XX:+UseG1GC"
export GRADLE_USER_HOME="$HOME/.gradle"

# Flutter优化
export FLUTTER_ROOT="$HOME/Flutter"
export PUB_CACHE="$HOME/.pub-cache"
```

## 📊 性能提升预期

| 操作 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| 首次构建 | 5-8分钟 | 3-5分钟 | 30-40% |
| 增量构建 | 2-3分钟 | 30-60秒 | 60-75% |
| 热重载 | 10-20秒 | 5-10秒 | 50% |
| APK生成 | 2-4分钟 | 1-2分钟 | 50% |

## 🛠️ 故障排除

### 如果构建仍然缓慢:
1. 检查内存使用: `flutter doctor -v`
2. 清理所有缓存: `flutter clean && rm -rf .dart_tool`
3. 重启IDE和终端
4. 检查磁盘空间 (至少保留5GB给缓存)

### 如果遇到缓存问题:
```bash
# 清理Gradle缓存
cd android && ./gradlew cleanBuildCache

# 清理Flutter缓存
flutter clean
rm -rf .dart_tool
rm -rf build
flutter packages get
```

---

现在你的Flutter项目应该有显著更快的构建速度了！ 🎉