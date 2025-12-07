import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// 主题切换按钮
class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            _getThemeIcon(ThemeService().themeMode),
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          tooltip: '切换主题',
          onSelected: (ThemeMode mode) async {
            await ThemeService().setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    color: ThemeService().themeMode == ThemeMode.light 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('浅色模式'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    color: ThemeService().themeMode == ThemeMode.dark 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('深色模式'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(
                    Icons.settings_brightness,
                    color: ThemeService().themeMode == ThemeMode.system 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('跟随系统'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 获取主题图标
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

/// 快速主题切换按钮（点击循环切换）
class QuickThemeSwitchButton extends StatelessWidget {
  const QuickThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            _getThemeIcon(ThemeService().themeMode),
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          tooltip: '当前：${ThemeService().currentThemeDisplayName}\n点击切换',
          onPressed: () async {
            await ThemeService().toggleTheme();
          },
        );
      },
    );
  }

  /// 获取主题图标
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}