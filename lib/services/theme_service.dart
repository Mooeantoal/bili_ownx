import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题管理服务
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  /// 当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 是否为黑夜模式
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
    }
  }

  /// 初始化主题服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);

    if (savedTheme != null) {
      _themeMode = _parseThemeMode(savedTheme);
    }

    // 监听系统主题变化
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        notifyListeners();
      }
    };
  }

  /// 预热主题数据
  Future<void> warmup() async {
    try {
      // 预计算主题颜色
      final context = WidgetsBinding.instance.platformDispatcher.views.first.context;
      if (context != null) {
        final theme = ThemeData.light();
        final darkTheme = ThemeData.dark();
        
        // 触发主题预计算
        theme.colorScheme;
        darkTheme.colorScheme;
      }
      
      debugPrint('🎨 主题数据预热完成');
    } catch (e) {
      debugPrint('⚠️ 主题预热失败: $e');
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_themeKey, _getThemeString(mode));
    notifyListeners();
  }

  /// 切换到下一个主题模式
  Future<void> toggleTheme() async {
    ThemeMode nextMode;
    switch (_themeMode) {
      case ThemeMode.light:
        nextMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        nextMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        nextMode = ThemeMode.light;
        break;
    }
    await setThemeMode(nextMode);
  }

  /// 解析主题模式字符串
  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 获取主题模式字符串
  String _getThemeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// 获取当前主题模式的显示名称
  String get currentThemeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取浅色主题配置
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFB7299), // Bilibili粉
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFFB7299),
        secondary: const Color(0xFF00A1D6),
        surface: Colors.white,
        background: const Color(0xFFF4F4F4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFB7299),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardTheme(  // 修复：使用 CardTheme 而不是 CardThemeData
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFB7299),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  /// 获取深色主题配置
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFB7299), // Bilibili粉
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFB7299),
        secondary: const Color(0xFF00A1D6),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D2D),
        foregroundColor: Color(0xFFFB7299),
        elevation: 0,
      ),
      cardTheme: const CardTheme(  // 修复：使用 CardTheme 而不是 CardThemeData
        elevation: 2,
        color: Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFB7299),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
      ),
    );
  }
}
