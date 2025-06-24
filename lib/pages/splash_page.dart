import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/database/database_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
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

    // 启动动画序列
    _startAnimations();
  }

  void _startAnimations() async {
    // 延迟一点开始动画
    await Future.delayed(const Duration(milliseconds: 200));

    // 同时启动两个动画
    _fadeController.forward();
    _scaleController.forward();
  }

  void _handleDatabaseInitialization(bool isInitialized) {
    if (isInitialized && !_isInitialized && !_hasNavigated) {
      setState(() {
        _isInitialized = true;
        _displayText = 'Flowm';
        _subtitleText = '智能财务管理';
      });

      // 数据已初始化，等待一段时间后跳转
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
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
          context.go('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 占位空间
              const Spacer(flex: 2),

              // 主要Logo区域
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_fadeAnimation, _scaleAnimation]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Logo文字
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  _displayText,
                                  key: ValueKey(_displayText),
                                  style: TextStyle(
                                    fontSize: _isInitialized ? 48 : 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: _isInitialized ? 2 : 1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 副标题
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  _subtitleText,
                                  key: ValueKey(_subtitleText),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // 装饰元素或加载指示器
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isInitialized
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildDot(0),
                                          const SizedBox(width: 8),
                                          _buildDot(1),
                                          const SizedBox(width: 8),
                                          _buildDot(2),
                                        ],
                                      )
                                    : const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white70),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 底部空间
              const Spacer(flex: 1),

              // 版权信息
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.7,
                      child: const Text(
                        'Powered by Flutter',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
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
