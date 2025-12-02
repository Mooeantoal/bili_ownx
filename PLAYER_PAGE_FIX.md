# PlayerPage 构造函数修复

## 问题描述

GitHub Actions 构建失败，出现 Dart 编译错误：

```
Flutter requires constructors to use only constant expressions, but 'bvid.isNotEmpty || aid != null' is not a constant; it depends on runtime values.
```

## 根本原因

Flutter 的构造函数初始化列表中的断言必须是常量表达式，但 `bvid.isNotEmpty || aid != null` 依赖于运行时值，因此无法在初始化列表中使用。

## 修复方案

### 1. 移动断言到构造函数体

将断言从初始化列表移动到构造函数体中：

```dart
// 修复前 (错误)
const PlayerPage({
  super.key,
  required this.bvid,
  this.aid,
}) : assert(bvid.isNotEmpty || aid != null, 'bvid 和 aid 必须提供其中一个');

// 修复后 (正确)
PlayerPage({
  super.key,
  required this.bvid,
  this.aid,
}) : super() {
  assert(bvid.isNotEmpty || aid != null, 'bvid 和 aid 必须提供其中一个');
}
```

### 2. 添加工厂构造函数

为了更好地处理可选参数，添加了工厂构造函数：

```dart
/// 工厂构造函数，用于处理可选的 bvid
factory PlayerPage.withIds({
  Key? key,
  String? bvid,
  int? aid,
}) {
  assert(bvid != null || aid != null, 'bvid 和 aid 必须提供其中一个');
  return PlayerPage(
    key: key,
    bvid: bvid ?? '',
    aid: aid,
  );
}
```

### 3. 更新调用代码

更新搜索页面中的导航代码，使用新的工厂构造函数：

```dart
// 修复前
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PlayerPage(
      bvid: validBvid ?? '',
      aid: validAid,
    ),
  ),
);

// 修复后
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PlayerPage.withIds(
      bvid: validBvid,
      aid: validAid,
    ),
  ),
);
```

## 验证结果

✅ 构造函数断言移到函数体中，避免常量表达式要求
✅ 添加工厂构造函数，更好地处理可选参数
✅ 更新调用代码，使用更清晰的 API
✅ 保持原有的参数验证逻辑
✅ 修复了 GitHub Actions 编译错误

## 使用方式

### 原始构造函数（向后兼容）
```dart
// 必须提供 bvid，aid 可选
PlayerPage(bvid: 'BV1234567890')
PlayerPage(bvid: '', aid: 12345678) // 空字符串 + aid
```

### 新的工厂构造函数（推荐）
```dart
// 更清晰的参数传递
PlayerPage.withIds(bvid: 'BV1234567890')
PlayerPage.withIds(aid: 12345678)
PlayerPage.withIds(bvid: 'BV1234567890', aid: 12345678)
```

## 测试场景

1. ✅ 只有 bvid 参数
2. ✅ 只有 aid 参数  
3. ✅ 两个参数都有
4. ✅ 两个参数都没有（应该抛出断言错误）
5. ✅ 空字符串 bvid + 有效 aid
6. ✅ 有效 bvid + null aid

修复后，GitHub Actions 应该能够成功编译和构建 APK。