import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_sync_service.dart';
import '../utils/file_time_utils.dart';

/// 冲突处理动作枚举
enum ConflictAction {
  cancel,         // 取消
  useLocal,       // 使用本地版本
  useRemote,      // 使用服务器版本
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
          Text(isStartup ? '启动时数据冲突' : '数据同步冲突'),
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
          _buildFileInfo(
            title: '📱 本地文件',
            time: conflict.localModified,
            size: conflict.localSize,
            isLocal: true,
          ),
          const SizedBox(height: 12),
          _buildFileInfo(
            title: '☁️ 服务器文件',
            time: conflict.remoteModified,
            size: conflict.remoteSize,
            isLocal: false,
          ),
          if (!isStartup) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
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
          ],
        ],
      ),
      actions: [
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
        TextButton(
          onPressed: () {
            if (onAction != null) {
              onAction!(ConflictAction.useRemote);
            } else {
              Navigator.of(context).pop(ConflictAction.useRemote);
            }
          },
          child: const Text('使用服务器版本'),
        ),
        ElevatedButton(
          onPressed: () {
            if (onAction != null) {
              onAction!(ConflictAction.useLocal);
            } else {
              Navigator.of(context).pop(ConflictAction.useLocal);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('使用本地版本'),
        ),
      ],
    );
  }

  Widget _buildFileInfo({
    required String title,
    required DateTime time,
    required int size,
    required bool isLocal,
  }) {
    final isNewer = isLocal 
      ? conflict.localModified.isAfter(conflict.remoteModified)
      : conflict.remoteModified.isAfter(conflict.localModified);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNewer ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNewer ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isNewer ? Colors.green.shade700 : Colors.orange.shade700,
                  fontSize: 13,
                ),
              ),
              if (isNewer) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.fiber_new,
                  color: Colors.green.shade700,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            FileTimeUtils.formatDateTime(time),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '${FileTimeUtils.getTimeAgo(time)} • ${FileTimeUtils.formatFileSize(size)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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