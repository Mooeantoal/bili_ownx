# BVID 空字符串错误修复

## 问题描述

用户报告的错误：
```
错误时间: 2025-12-02T21:22:48.533142
错误类型: DioException
错误信息: DioException [unknown]: null
Error: FormatException: Unexpected character (at offset 0)

附加信息:
视频BVID: , CID: 34335359992
```

## 根本原因

1. **空 BVID 传递**: 当视频只有 AID 没有 BVID 时，空字符串被直接传递给 API
2. **缺少参数验证**: `VideoApi.getPlayUrl` 方法没有对空 BVID 进行验证
3. **URL 构建错误**: 空 BVID 导致 API URL 构建异常，进而导致 DioException

## 修复方案

### 1. 在 VideoApi 中添加参数验证

```dart
static Future<Map<String, dynamic>> getPlayUrl({
  required String bvid,
  required int cid,
  int qn = 80,
  int fnval = 16,
}) async {
  try {
    // 验证参数
    if (bvid.isEmpty) {
      throw ArgumentError('BVID 不能为空');
    }
    
    if (cid <= 0) {
      throw ArgumentError('CID 必须大于 0');
    }
    
    // ... 继续处理
  }
}
```

### 2. 在 PlayerPage 中增强 BVID 处理逻辑

```dart
Future<void> _loadPlayUrl(int cid) async {
  try {
    // 确定要使用的 bvid
    String bvidToUse = widget.bvid;
    
    // 如果 widget.bvid 为空，尝试从 _videoInfo 获取
    if (bvidToUse.isEmpty && _videoInfo != null && _videoInfo!.bvid.isNotEmpty) {
      bvidToUse = _videoInfo!.bvid;
      print('使用从视频信息中获取的 BVID: $bvidToUse');
    }
    
    // 最终验证
    if (bvidToUse.isEmpty) {
      throw Exception('无法获取有效的 BVID：widget.bvid 为空，且无法从视频信息中获取');
    }
    
    final response = await VideoApi.getPlayUrl(
      bvid: bvidToUse,
      cid: cid,
      qn: _selectedQuality,
    );
    
    // ... 继续处理
  }
}
```

## 修复流程

### 场景1: 只有 BVID
- ✅ 直接使用 widget.bvid
- ✅ 参数验证通过
- ✅ 正常调用 API

### 场景2: 只有 AID
- ✅ 先调用 getVideoDetail 获取完整信息
- ✅ 从 VideoInfo 中获取 bvid
- ✅ 使用获取的 bvid 调用 getPlayUrl

### 场景3: BVID 和 AID 都有
- ✅ 优先使用 widget.bvid
- ✅ 如果为空则从 VideoInfo 获取
- ✅ 确保有有效的 bvid 才调用 API

### 场景4: 无效参数
- ✅ 空 BVID → 抛出 ArgumentError
- ✅ 无效 CID → 抛出 ArgumentError
- ✅ 提供清晰的错误信息

## 错误处理改进

### 之前
- 空字符串直接传递给 API
- 导致 DioException 和 FormatException
- 错误信息不明确

### 修复后
- 提前验证参数
- 抛出明确的 ArgumentError
- 提供清晰的错误信息
- 支持从视频信息中恢复 BVID

## 测试场景

1. ✅ 空 BVID → ArgumentError
2. ✅ 无效 CID (0) → ArgumentError  
3. ✅ 无效 CID (负数) → ArgumentError
4. ✅ 有效参数 → 正常调用
5. ✅ 空 BVID 但有 VideoInfo → 从 VideoInfo 获取 BVID

## 预期效果

修复后的系统将：
1. **提前发现错误**: 在 API 调用前验证参数
2. **提供清晰错误**: 明确指出是 BVID 为空还是 CID 无效
3. **自动恢复**: 当 BVID 为空时尝试从视频信息获取
4. **避免异常**: 防止 DioException 和 FormatException

## 相关文件

- `lib/api/video_api.dart`: 添加参数验证
- `lib/pages/player_page.dart`: 增强 BVID 处理逻辑
- `lib/models/video_info.dart`: 确保包含 bvid 字段

修复后，用户在播放只有 AID 的视频时应该不再遇到 DioException 错误。