import 'package:flutter/material.dart';
import '../models/danmaku.dart';

/// 弹幕输入组件
class DanmakuInput extends StatefulWidget {
  final Function(Danmaku) onSend;
  final bool enabled;

  const DanmakuInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<DanmakuInput> createState() => _DanmakuInputState();
}

class _DanmakuInputState extends State<DanmakuInput> {
  final TextEditingController _controller = TextEditingController();
  DanmakuType _selectedType = DanmakuType.scroll;
  Color _selectedColor = Colors.white;
  double _selectedFontSize = 16.0;

  final List<Color> _colors = [
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.cyan,
  ];

  final List<double> _fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0, 24.0];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendDanmaku() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final danmaku = Danmaku(
      text: text,
      color: _selectedColor,
      fontSize: _selectedFontSize,
      type: _selectedType,
      time: DateTime.now(),
    );

    widget.onSend(danmaku);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 输入框和发送按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  decoration: const InputDecoration(
                    hintText: '发个友善的弹幕见证当下',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendDanmaku(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.enabled ? _sendDanmaku : null,
                child: const Text('发送'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 弹幕设置
          Row(
            children: [
              // 弹幕类型选择
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('弹幕类型', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTypeButton(DanmakuType.scroll, '滚动'),
                        const SizedBox(width: 4),
                        _buildTypeButton(DanmakuType.top, '顶部'),
                        const SizedBox(width: 4),
                        _buildTypeButton(DanmakuType.bottom, '底部'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 颜色选择
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('颜色', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: _colors.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _selectedColor == color
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 字体大小选择
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('字体大小', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: _fontSizes.map((size) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFontSize = size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _selectedFontSize == size
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        size.toInt().toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFontSize == size
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(DanmakuType type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}