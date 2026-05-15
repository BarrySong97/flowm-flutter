import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/database/database_provider.dart';
import '../utils/web_message_sender.dart';
import '../services/auto_sync_service.dart';
import '../services/webdav_config.dart';
import '../utils/sync_dialog_helper.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  bool _isInitialized = false;
  String _displayText = '数据初始化中...';
  bool _hasNavigated = false;

  // 新增：同步相关状态
  bool _isSyncing = false;
  String _syncProgress = '';
  bool _hasSyncError = false;

  @override
  void initState() {
    super.initState();

    // 标题动画控制器
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

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
    _titleController.forward();
  }

  void _handleDatabaseInitialization(bool isInitialized) async {
    if (isInitialized && !_isInitialized && !_hasNavigated) {
      setState(() {
        _isInitialized = true;
        _displayText = 'FLOWM';
      });

      // 数据库初始化完成后，检查是否需要同步
      await _checkStartupSync();

      // 等待一段时间后跳转（如果没有同步操作）
      if (!_isSyncing && !_hasNavigated) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToMain();
        });
      }
    }
  }

  /// 检查是否曾经同步过
  Future<bool> _checkIfEverSynced() async {
    try {
      final lastSyncTime = await WebDAVConfig.getLastSyncTime();
      final lastLocalHash = await WebDAVConfig.getLastLocalHash();
      final lastRemoteHash = await WebDAVConfig.getLastRemoteHash();

      return lastSyncTime != null ||
          lastLocalHash != null ||
          lastRemoteHash != null;
    } catch (e) {
      AppLogger.debug('[SplashPage] 检查同步历史失败: $e');
      return false;
    }
  }

  /// 检查启动时同步
  Future<void> _checkStartupSync() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncProgress = '检查同步状态...';
      });

      final checkResult = await AutoSyncService.checkStartupSync();

      if (!checkResult.shouldSync) {
        // 不需要同步
        AppLogger.debug('[SplashPage] 不需要同步: ${checkResult.message}');
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      if (checkResult.direction == SyncDirection.conflict) {
        // 有冲突，需要用户选择
        setState(() {
          _isSyncing = false;
        });

        // 检查是否为首次配置情况
        final hasEverSynced = await _checkIfEverSynced();
        if (!hasEverSynced) {
          // 首次配置发现云端数据
          await _showFirstTimeDataDialog(checkResult);
        } else {
          // 普通冲突情况
          await _showConflictDialog(checkResult);
        }
        return;
      }

      // 执行同步
      final success = await AutoSyncService.executeStartupSync(
        checkResult,
        ref,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _syncProgress = progress;
            });
          }
        },
      );

      setState(() {
        _isSyncing = false;
        if (success) {
        } else {
          _hasSyncError = true;
        }
      });

      // 同步完成后跳转
      if (mounted && !_hasNavigated) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          _navigateToMain();
        });
      }
    } catch (e) {
      AppLogger.debug('[SplashPage] 同步检查失败: $e');
      setState(() {
        _isSyncing = false;
        _hasSyncError = true;
      });

      // 错误情况下也要跳转
      if (mounted && !_hasNavigated) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToMain();
        });
      }
    }
  }

  /// 显示首次配置数据发现对话框
  Future<void> _showFirstTimeDataDialog(SyncCheckResult checkResult) async {
    if (!mounted) return;

    final action = await showDialog<SyncDirection>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('发现云端数据'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '云端已有数据文件，这可能是：',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            SizedBox(height: 12),
            _buildOptionRow(Icons.phone_android, '您在其他设备上的数据'),
            _buildOptionRow(Icons.backup, '之前的备份数据'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '推荐选择"下载云端数据"以避免数据丢失',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (checkResult.conflict != null) ...[
              SizedBox(height: 16),
              Text(
                '文件信息：',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '云端文件: ${_formatDateTime(checkResult.conflict!.remoteModified)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                '文件大小: ${_formatFileSize(checkResult.conflict!.remoteSize)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 16),
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
                      '⚠️ 重要提醒：\n'
                      '• 下载云端数据将覆盖本地数据\n'
                      '• 使用本地数据将覆盖云端数据\n'
                      '• 操作不可撤销，请谨慎选择',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        height: 1.3,
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
                          TextSpan(text: '• 选择“下载云端数据”将覆盖本地数据\n'),
                          TextSpan(text: '• 选择“使用本地数据”将覆盖云端数据\n\n'),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.none),
            child: Text(
              '暂不同步',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          SyncDialogHelper.buildInitialSyncButton(
            text: '使用本地数据\n(覆盖云端)',
            onPressed: () => Navigator.of(context).pop(SyncDirection.upload),
            recommendation: SyncDirection.none, // 首次发现云端数据时不推荐上传
            buttonType: SyncDirection.upload,
            icon: Icons.cloud_upload,
          ),
          SyncDialogHelper.buildInitialSyncButton(
            text: '下载云端数据\n(推荐)',
            onPressed: () => Navigator.of(context).pop(SyncDirection.download),
            recommendation: SyncDirection.download, // 推荐下载
            buttonType: SyncDirection.download,
            icon: Icons.cloud_download,
          ),
        ],
      ),
    );

    await _handleSyncAction(action);
  }

  /// 显示冲突对话框
  Future<void> _showConflictDialog(SyncCheckResult checkResult) async {
    if (!mounted) return;

    if (checkResult.conflict == null) {
      await _handleSyncAction(null);
      return;
    }

    final conflict = checkResult.conflict!;
    final recommendation = SyncDialogHelper.getConflictRecommendation(conflict);

    final action = await showDialog<SyncDirection>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('数据同步冲突'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本地和服务器的数据都有更新，请选择如何处理：'),
            const SizedBox(height: 16),

            // 文件信息对比
            SyncDialogHelper.buildFileInfoContainer(
              conflict: conflict,
              localIsNewerChecker: (c) =>
                  c.localModified.isAfter(c.remoteModified),
              remoteIsNewerChecker: (c) =>
                  c.remoteModified.isAfter(c.localModified),
              dateFormatter: _formatDateTime,
              sizeFormatter: _formatFileSize,
            ),

            // 智能建议
            if (recommendation.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              SyncDialogHelper.buildRecommendationContainer(
                message: recommendation.message,
                color: recommendation.color,
                icon: recommendation.icon,
              ),
            ],

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
                          TextSpan(text: '• 选择“使用本地数据”将覆盖服务器数据\n'),
                          TextSpan(text: '• 选择“使用服务器数据”将覆盖本地数据\n\n'),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.none),
            child: const Text('跳过同步'),
          ),
          SyncDialogHelper.buildConflictButton(
            text: '使用服务器数据',
            onPressed: () => Navigator.of(context).pop(SyncDirection.download),
            isRecommended: recommendation.recommendedAction ==
                ConflictButtonType.useRemote,
            buttonType: ConflictButtonType.useRemote,
          ),
          const SizedBox(width: 8),
          SyncDialogHelper.buildConflictButton(
            text: '使用本地数据',
            onPressed: () => Navigator.of(context).pop(SyncDirection.upload),
            isRecommended:
                recommendation.recommendedAction == ConflictButtonType.useLocal,
            buttonType: ConflictButtonType.useLocal,
            isElevated: true,
          ),
        ],
      ),
    );

    await _handleSyncAction(action);
  }

  /// 构建选项行
  Widget _buildOptionRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  /// 处理同步动作
  Future<void> _handleSyncAction(SyncDirection? action) async {
    if (action != null && action != SyncDirection.none) {
      // 执行用户选择的同步操作
      setState(() {
        _isSyncing = true;
        _syncProgress =
            action == SyncDirection.download ? '正在下载服务器数据...' : '正在上传本地数据...';
      });

      final success = await AutoSyncService.forcSync(ref, action);

      setState(() {
        _isSyncing = false;
        _hasSyncError = !success;
      });
    } else {
      setState(() {});
    }

    // 冲突处理完成后跳转
    if (mounted && !_hasNavigated) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _navigateToMain();
      });
    }
  }

  /// 导航到主页面
  void _navigateToMain() {
    if (_hasNavigated) return;

    _hasNavigated = true;
    if (kIsWeb) {
      sendWebMessage('app_ready', '*');
    }
    context.go('/');
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _handleDatabaseError() {
    if (!_hasNavigated) {
      // 发生错误，显示默认文字并跳转
      setState(() {
        _isInitialized = true;
        _displayText = 'Flowm';
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
      body: SizedBox(
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

              // 同步状态指示器
              if (_isSyncing)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.fromRGBO(12, 12, 48, 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _syncProgress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromRGBO(12, 12, 48, 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

              // 同步错误提示
              if (_hasSyncError && !_isSyncing)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
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
}
