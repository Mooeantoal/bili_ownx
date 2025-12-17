import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/startup_service.dart';
import '../services/performance_service.dart';
import 'main_page.dart';

/// 快速启动页面 - 优化启动体验
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  String _statusText = '正在启动...';
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    
    // 设置状态栏为沉浸式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // 创建动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // 开始启动流程
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final performanceService = PerformanceService();
    performanceService.startTimer('splash_display');
    
    try {
      // 开始动画
      _fadeController.forward();
      _scaleController.forward();
      
      setState(() => _statusText = '初始化服务...');
      
      // 并行初始化所有服务
      await StartupService.initialize();
      
      setState(() => _statusText = '准备完成...');
      
      // 等待最短显示时间，确保用户能看到启动画面
      await Future.delayed(const Duration(milliseconds: 500));
      
      performanceService.endTimer('splash_display');
      
      // 跳转到主页面
      if (mounted) {
        _navigateToMain();
      }
      
    } catch (e) {
      setState(() => _statusText = '启动失败: $e');
      
      // 如果启动失败，等待一段时间后重试或跳转
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        _navigateToMain();
      }
    }
  }
  
  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 动画
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00A1D6), Color(0xFF00B5E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A1D6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // 应用名称
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    'Bilimiao',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A1D6),
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // 版本信息
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.8,
                  child: Text(
                    _versionInfo.isNotEmpty ? _versionInfo : 'v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 64),
            
            // 加载状态
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00A1D6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}