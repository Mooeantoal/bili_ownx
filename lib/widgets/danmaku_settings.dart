import 'package:flutter/material.dart';

/// 弹幕设置组件
class DanmakuSettings extends StatefulWidget {
  final bool showScroll;
  final bool showTop;
  final bool showBottom;
  final double opacity;
  final double fontSize;
  final int maxCount;
  final Function(bool) onScrollToggle;
  final Function(bool) onTopToggle;
  final Function(bool) onBottomToggle;
  final Function(double) onOpacityChange;
  final Function(double) onFontSizeChange;
  final Function(int) onMaxCountChange;

  const DanmakuSettings({
    super.key,
    this.showScroll = true,
    this.showTop = true,
    this.showBottom = true,
    this.opacity = 1.0,
    this.fontSize = 16.0,
    this.maxCount = 100,
    required this.onScrollToggle,
    required this.onTopToggle,
    required this.onBottomToggle,
    required this.onOpacityChange,
    required this.onFontSizeChange,
    required this.onMaxCountChange,
  });

  @override
  State<DanmakuSettings> createState() => _DanmakuSettingsState();
}

class _DanmakuSettingsState extends State<DanmakuSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '弹幕设置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // 弹幕类型开关
          _buildToggleSection(
            '弹幕类型',
            [
              _buildToggleItem('滚动弹幕', widget.showScroll, widget.onScrollToggle),
              _buildToggleItem('顶部弹幕', widget.showTop, widget.onTopToggle),
              _buildToggleItem('底部弹幕', widget.showBottom, widget.onBottomToggle),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 透明度调节
          _buildSliderSection(
            '透明度',
            widget.opacity,
            0.0,
            1.0,
            widget.onOpacityChange,
            '${(widget.opacity * 100).toInt()}%',
          ),
          
          const SizedBox(height: 16),
          
          // 字体大小调节
          _buildSliderSection(
            '字体大小',
            widget.fontSize,
            12.0,
            24.0,
            widget.onFontSizeChange,
            '${widget.fontSize.toInt()}px',
          ),
          
          const SizedBox(height: 16),
          
          // 最大弹幕数量
          _buildSliderSection(
            '最大弹幕数',
            widget.maxCount.toDouble(),
            10.0,
            200.0,
            (value) => widget.onMaxCountChange(value.toInt()),
            '${widget.maxCount}条',
            divisions: 19,
          ),
          
          const SizedBox(height: 16),
          
          // 预设方案
          _buildPresetSection(),
        ],
      ),
    );
  }

  Widget _buildToggleSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildToggleItem(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String label, {
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预设方案',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPresetButton('默认', _applyDefaultPreset),
            _buildPresetButton('沉浸', _applyImmersivePreset),
            _buildPresetButton('简约', _applyMinimalPreset),
            _buildPresetButton('密集', _applyDensePreset),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _applyDefaultPreset() {
    widget.onScrollToggle(true);
    widget.onTopToggle(true);
    widget.onBottomToggle(true);
    widget.onOpacityChange(1.0);
    widget.onFontSizeChange(16.0);
    widget.onMaxCountChange(100);
  }

  void _applyImmersivePreset() {
    widget.onScrollToggle(true);
    widget.onTopToggle(false);
    widget.onBottomToggle(false);
    widget.onOpacityChange(0.7);
    widget.onFontSizeChange(18.0);
    widget.onMaxCountChange(50);
  }

  void _applyMinimalPreset() {
    widget.onScrollToggle(true);
    widget.onTopToggle(false);
    widget.onBottomToggle(false);
    widget.onOpacityChange(0.5);
    widget.onFontSizeChange(14.0);
    widget.onMaxCountChange(30);
  }

  void _applyDensePreset() {
    widget.onScrollToggle(true);
    widget.onTopToggle(true);
    widget.onBottomToggle(true);
    widget.onOpacityChange(0.8);
    widget.onFontSizeChange(14.0);
    widget.onMaxCountChange(150);
  }
}