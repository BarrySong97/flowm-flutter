import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_sync_service.dart';
import '../utils/file_time_utils.dart';
import '../utils/sync_dialog_helper.dart';

/// 冲突处理动作枚举
enum ConflictAction {
  cancel, // 取消
  useLocal, // 使用本地版本
  useRemote, // 使用服务器版本
}

/// 全局冲突对话框服务
class ConflictDialogService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 显示全局冲突对话框
  static Future<ConflictAction?> showConflictDialog(
    BuildContext context,
    SyncConflict conflict, {
    bool isStartup = false,
  }) async {
    if (_isShowing) {
      // 如果已经在显示对话框，不重复显示
      return null;
    }

    _isShowing = true;

    try {
      if (isStartup) {
        // 启动时使用阻塞式对话框
        return await _showStartupConflictDialog(context, conflict);
      } else {
        // 运行时使用全局浮层对话框
        return await _showGlobalConflictDialog(context, conflict);
      }
    } finally {
      _isShowing = false;
    }
  }

  /// 启动时阻塞式冲突对话框
  static Future<ConflictAction?> _showStartupConflictDialog(
    BuildContext context,
    SyncConflict conflict,
  ) async {
    return await showDialog<ConflictAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConflictDialog(
        conflict: conflict,
        isStartup: true,
      ),
    );
  }

  /// 全局浮层冲突对话框
  static Future<ConflictAction?> _showGlobalConflictDialog(
    BuildContext context,
    SyncConflict conflict,
  ) async {
    final completer = Completer<ConflictAction?>();

    _overlayEntry = OverlayEntry(
      builder: (context) => _GlobalConflictOverlay(
        conflict: conflict,
        onAction: (action) {
          _hideGlobalDialog();
          completer.complete(action);
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    return completer.future;
  }

  /// 隐藏全局对话框
  static void _hideGlobalDialog() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 检查是否正在显示冲突对话框
  static bool get isShowing => _isShowing;
}

/// 冲突对话框组件
class _ConflictDialog extends StatelessWidget {
  final SyncConflict conflict;
  final bool isStartup;
  final Function(ConflictAction)? onAction;

  const _ConflictDialog({
    required this.conflict,
    required this.isStartup,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text('数据同步冲突'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStartup
                ? '检测到本地和服务器的数据都有更新，请选择如何处理：'
                : '在同步过程中检测到冲突，本地和服务器的数据都有更新：',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // 使用统一的文件信息容器
          SyncDialogHelper.buildFileInfoContainer(
            conflict: conflict,
            localIsNewerChecker: (c) =>
                c.localModified.isAfter(c.remoteModified),
            remoteIsNewerChecker: (c) =>
                c.remoteModified.isAfter(c.localModified),
            dateFormatter: FileTimeUtils.formatDateTime,
            sizeFormatter: FileTimeUtils.formatFileSize,
          ),

          // 智能建议
          const SizedBox(height: 12),
          _buildRecommendationContainer(),

          const SizedBox(height: 12),
          // 覆盖警告
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ 重要提醒：选择任何版本都将完全覆盖另一版本的数据，操作不可撤销！',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isStartup) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '为避免数据丢失，建议选择较新的版本',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // WebDAV版本信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        children: const [
                          TextSpan(
                            text: '📝 操作说明：\n',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: '• 选择“使用本地版本”将覆盖服务器数据\n'),
                          TextSpan(text: '• 选择“使用服务器版本”将覆盖本地数据\n\n'),
                          TextSpan(
                            text: '💾 数据备份：',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                              text:
                                  '大多WebDAV服务器具有文件历史版本功能，被覆盖的数据可能可以从服务器历史记录中恢复。'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildRecommendationContainer() {
    final recommendation = SyncDialogHelper.getConflictRecommendation(conflict);
    return SyncDialogHelper.buildRecommendationContainer(
      message: recommendation.message,
      color: recommendation.color,
      icon: recommendation.icon,
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final recommendation = SyncDialogHelper.getConflictRecommendation(conflict);

    return [
      TextButton(
        onPressed: () {
          if (onAction != null) {
            onAction!(ConflictAction.cancel);
          } else {
            Navigator.of(context).pop(ConflictAction.cancel);
          }
        },
        child: Text(
          isStartup ? '跳过同步' : '取消',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
      SyncDialogHelper.buildConflictButton(
        text: '使用服务器版本',
        onPressed: () {
          if (onAction != null) {
            onAction!(ConflictAction.useRemote);
          } else {
            Navigator.of(context).pop(ConflictAction.useRemote);
          }
        },
        isRecommended:
            recommendation.recommendedAction == ConflictButtonType.useRemote,
        buttonType: ConflictButtonType.useRemote,
      ),
      const SizedBox(width: 8),
      SyncDialogHelper.buildConflictButton(
        text: '使用本地版本',
        onPressed: () {
          if (onAction != null) {
            onAction!(ConflictAction.useLocal);
          } else {
            Navigator.of(context).pop(ConflictAction.useLocal);
          }
        },
        isRecommended:
            recommendation.recommendedAction == ConflictButtonType.useLocal,
        buttonType: ConflictButtonType.useLocal,
        isElevated: true,
      ),
    ];
  }
}

/// 全局浮层冲突对话框
class _GlobalConflictOverlay extends StatefulWidget {
  final SyncConflict conflict;
  final Function(ConflictAction?) onAction;

  const _GlobalConflictOverlay({
    required this.conflict,
    required this.onAction,
  });

  @override
  State<_GlobalConflictOverlay> createState() => _GlobalConflictOverlayState();
}

class _GlobalConflictOverlayState extends State<_GlobalConflictOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleAction(ConflictAction action) {
    _animationController.reverse().then((_) {
      widget.onAction(action);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _ConflictDialog(
                    conflict: widget.conflict,
                    isStartup: false,
                    onAction: _handleAction,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
