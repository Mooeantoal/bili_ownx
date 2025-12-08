import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../widgets/theme_switch_button.dart';
import 'pip_test_page.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [
          ThemeSwitchButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(context),
          const SizedBox(height: 20),
          _buildVideoSection(context),
          const SizedBox(height: 20),
          _buildCommentSection(context),
          const SizedBox(height: 20),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  /// 构建视频设置部分
  Widget _buildVideoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '视频设置',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.picture_in_picture),
              title: const Text('画中画模式'),
              subtitle: const Text('支持小窗播放视频'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PiPTestPage(),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.high_quality),
              title: const Text('默认画质'),
              subtitle: const Text('设置视频播放的默认画质'),
              trailing: const Text('超清'),
              onTap: () {
                // TODO: 打开画质选择对话框
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('画质设置功能开发中...')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.play_lesson),
              title: const Text('自动播放'),
              subtitle: const Text('进入播放页面时自动开始播放'),
              trailing: Switch(
                value: false, // TODO: 从设置中读取
                onChanged: (value) {
                  // TODO: 保存设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(value ? '已启用自动播放' : '已禁用自动播放')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建评论设置部分
  Widget _buildCommentSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '评论设置',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('评论排序'),
              subtitle: const Text('设置评论列表的默认排序方式'),
              trailing: const Text('热门'),
              onTap: () {
                // TODO: 打开排序选择对话框
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('评论排序'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('热门'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text('最新'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text('最热'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.thumb_up),
              title: const Text('自动加载图片'),
              subtitle: const Text('自动显示评论中的图片和头像'),
              trailing: Switch(
                value: true, // TODO: 从设置中读取
                onChanged: (value) {
                  // TODO: 保存设置
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(value ? '已启用自动加载图片' : '已禁用自动加载图片')),
                  );
                },
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('屏蔽管理'),
              subtitle: const Text('管理屏蔽的用户和关键词'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 打开屏蔽管理页面
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('屏蔽管理功能开发中...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主题设置部分
  Widget _buildThemeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '主题设置',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 当前主题状态
            ListenableBuilder(
              listenable: ThemeService(),
              builder: (context, child) {
                return Column(
                  children: [
                    _ThemeOption(
                      title: '浅色模式',
                      icon: Icons.light_mode,
                      value: ThemeMode.light,
                      currentMode: ThemeService().themeMode,
                      onTap: () => ThemeService().setThemeMode(ThemeMode.light),
                    ),
                    _ThemeOption(
                      title: '深色模式',
                      icon: Icons.dark_mode,
                      value: ThemeMode.dark,
                      currentMode: ThemeService().themeMode,
                      onTap: () => ThemeService().setThemeMode(ThemeMode.dark),
                    ),
                    _ThemeOption(
                      title: '跟随系统',
                      icon: Icons.settings_brightness,
                      value: ThemeMode.system,
                      currentMode: ThemeService().themeMode,
                      onTap: () => ThemeService().setThemeMode(ThemeMode.system),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 当前状态显示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, 
                               color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '当前设置：${ThemeService().currentThemeDisplayName}'
                              '${ThemeService().themeMode == ThemeMode.system ? 
                                (ThemeService().isDarkMode ? '（深色）' : '（浅色）') : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关于部分
  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '关于应用',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Bilibili Flutter'),
              subtitle: const Text('哔哩哔哩视频播放器'),
              onTap: () {},
            ),
            
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('版本'),
              subtitle: const Text('1.0.0'),
              onTap: () {},
            ),
            
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('主题'),
              subtitle: const Text('支持浅色/深色/跟随系统'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// 主题选项组件
class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode currentMode;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentMode;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}