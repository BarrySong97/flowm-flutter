import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter/material.dart';

class SnackBarUtils {
  static OverlayEntry? _currentOverlay;

  /// 使用Overlay在真正的顶层显示消息，带有从下往上的滑动动画
  static void showOverlayMessage(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    int? durationSeconds,
    double bottomMargin = 0, // 改为0，因为我们要占满宽度
  }) {
    // 移除之前的overlay
    _currentOverlay?.remove();
    _currentOverlay = null;

    try {
      final overlay = Overlay.of(context);

      final overlayEntry = OverlayEntry(
        builder: (context) => _AnimatedSnackBarOverlay(
          message: message,
          backgroundColor: backgroundColor ?? Colors.red,
          durationSeconds: durationSeconds ?? 3,
          onComplete: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
          },
        ),
      );

      overlay.insert(overlayEntry);
      _currentOverlay = overlayEntry;
    } catch (e) {
      AppLogger.debug('Overlay显示失败，回退到标准SnackBar: $e');

      // 如果overlay失败，回退到标准SnackBar
      try {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor ?? Colors.red,
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: durationSeconds ?? 3),
          ),
        );
      } catch (fallbackError) {
        AppLogger.debug('SnackBar也失败了: $fallbackError');
      }
    }
  }

  /// 根据背景色获取合适的图标
  static IconData _getIconForColor(Color? color) {
    if (color == Colors.green) {
      return Icons.check_circle;
    } else if (color == Colors.orange) {
      return Icons.warning;
    } else if (color == Colors.blue) {
      return Icons.info;
    } else {
      return Icons.error;
    }
  }

  /// 在根级显示SnackBar，确保它显示在所有overlay之上
  static void showTopLevelSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    int? durationSeconds,
  }) {
    // 使用根上下文的ScaffoldMessenger
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
        behavior: SnackBarBehavior.fixed,
        duration: Duration(
          seconds: durationSeconds ?? (message.contains('交易记录') ? 4 : 2),
        ),
      ),
    );
  }

  /// 显示成功消息
  static void showSuccess(BuildContext context, String message) {
    showTopLevelSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      durationSeconds: 2,
    );
  }

  /// 显示错误消息
  static void showError(BuildContext context, String message) {
    showTopLevelSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      durationSeconds: 3,
    );
  }

  /// 显示警告消息
  static void showWarning(BuildContext context, String message) {
    showTopLevelSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      durationSeconds: 3,
    );
  }

  /// 显示信息消息
  static void showInfo(BuildContext context, String message) {
    showTopLevelSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      durationSeconds: 2,
    );
  }

  /// 使用Overlay显示成功消息
  static void showOverlaySuccess(BuildContext context, String message) {
    showOverlayMessage(
      context,
      message,
      backgroundColor: Colors.green,
      durationSeconds: 2,
    );
  }

  /// 使用Overlay显示错误消息
  static void showOverlayError(BuildContext context, String message) {
    showOverlayMessage(
      context,
      message,
      backgroundColor: Colors.red,
      durationSeconds: 3,
    );
  }

  /// 使用Overlay显示警告消息
  static void showOverlayWarning(BuildContext context, String message) {
    showOverlayMessage(
      context,
      message,
      backgroundColor: Colors.orange,
      durationSeconds: 3,
    );
  }

  /// 测试方法：直接显示一个简单的overlay消息
  static void testOverlay(BuildContext context) {
    AppLogger.debug('测试 Overlay 功能');
    showOverlayMessage(
      context,
      '这是一个测试消息',
      backgroundColor: Colors.blue,
      durationSeconds: 2,
    );
  }
}

/// 动画化的SnackBar Overlay组件
class _AnimatedSnackBarOverlay extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final int durationSeconds;
  final VoidCallback onComplete;

  const _AnimatedSnackBarOverlay({
    required this.message,
    required this.backgroundColor,
    required this.durationSeconds,
    required this.onComplete,
  });

  @override
  State<_AnimatedSnackBarOverlay> createState() =>
      _AnimatedSnackBarOverlayState();
}

class _AnimatedSnackBarOverlayState extends State<_AnimatedSnackBarOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 创建滑动动画控制器
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 创建从下往上的滑动动画
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // 从下方开始
      end: Offset.zero, // 滑动到正常位置
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 开始进入动画
    _slideController.forward();

    // 设置自动消失
    Future.delayed(Duration(seconds: widget.durationSeconds), () {
      if (mounted) {
        _slideOut();
      }
    });
  }

  void _slideOut() async {
    if (!mounted) return;

    try {
      await _slideController.reverse();
      widget.onComplete();
    } catch (e) {
      AppLogger.debug('退出动画错误: $e');
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(
                    SnackBarUtils._getIconForColor(widget.backgroundColor),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // 可选：添加关闭按钮
                  GestureDetector(
                    onTap: _slideOut,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
