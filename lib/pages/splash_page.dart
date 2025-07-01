import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/database/database_provider.dart';
import '../utils/web_message_sender.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _titleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  bool _isInitialized = false;
  String _displayText = '数据初始化中...';
  String _subtitleText = '正在准备您的财务数据';
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 淡入动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 标题动画控制器
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // "流记"标题浮现动画
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // displayText浮现动画
    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    // 启动动画序列
    _startAnimations();
  }

  void _startAnimations() async {
    // 延迟一点开始动画
    await Future.delayed(const Duration(milliseconds: 200));

    // 同时启动动画
    _fadeController.forward();
    _scaleController.forward();
    _titleController.forward();
  }

  void _handleDatabaseInitialization(bool isInitialized) {
    if (isInitialized && !_isInitialized && !_hasNavigated) {
      setState(() {
        _isInitialized = true;
        _displayText = 'FLOWM';
        _subtitleText = '智能财务管理';
      });

      // 数据已初始化，等待一段时间后跳转
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          if (kIsWeb) {
            // 在Web环境下发送消息
            sendWebMessage('app_ready', '*');
          }
          context.go('/');
        }
      });
    }
  }

  void _handleDatabaseError() {
    if (!_hasNavigated) {
      // 发生错误，显示默认文字并跳转
      setState(() {
        _isInitialized = true;
        _displayText = 'Flowm';
        _subtitleText = '智能财务管理';
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          if (kIsWeb) {
            // 在Web环境下发送消息
            sendWebMessage('app_ready', '*');
          }
          context.go('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听数据库初始化状态
    final databaseInitState = ref.watch(databaseInitializationProvider);

    // 处理数据库状态
    databaseInitState.when(
      data: _handleDatabaseInitialization,
      loading: () {
        // 保持当前状态：数据初始化中
      },
      error: (error, stackTrace) => _handleDatabaseError(),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [
        //       Color.fromARGB(255, 171, 216, 178),
        //       Color(0xFF8BFFC7),
        //     ],
        //   ),
        // ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "流记"标题 - 带浮现动画
              SlideTransition(
                position: _titleSlideAnimation,
                child: FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "流记",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(12, 12, 48, 1),
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),

              // displayText - 带浮现动画
              SlideTransition(
                position: _subtitleSlideAnimation,
                child: FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      key: ValueKey(_displayText),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _displayText,
                        style: TextStyle(
                          fontSize: _isInitialized ? 28 : 24,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(12, 12, 48, 0.8),
                          letterSpacing: _isInitialized ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 主要Logo区域

              // 底部空间

              // 版权信息
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        // 创建一个延迟的动画效果
        final delay = index * 0.2;
        final progress = (_fadeController.value - delay).clamp(0.0, 1.0);

        return Transform.scale(
          scale: progress,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
