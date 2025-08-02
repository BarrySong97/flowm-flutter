import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/database/database_provider.dart';
import '../utils/web_message_sender.dart';
import '../services/auto_sync_service.dart';
import '../services/webdav_config.dart';

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
  
  // 新增：同步相关状态
  bool _isSyncing = false;
  String _syncProgress = '';
  bool _hasSyncError = false;

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

  void _handleDatabaseInitialization(bool isInitialized) async {
    if (isInitialized && !_isInitialized && !_hasNavigated) {
      setState(() {
        _isInitialized = true;
        _displayText = 'FLOWM';
        _subtitleText = '智能财务管理';
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
      print('[SplashPage] 检查同步历史失败: $e');
      return false;
    }
  }

  /// 检查启动时同步
  Future<void> _checkStartupSync() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncProgress = '检查同步状态...';
        _subtitleText = _syncProgress;
      });

      final checkResult = await AutoSyncService.checkStartupSync();
      
      if (!checkResult.shouldSync) {
        // 不需要同步
        print('[SplashPage] 不需要同步: ${checkResult.message}');
        setState(() {
          _isSyncing = false;
          _subtitleText = '智能财务管理';
        });
        return;
      }

      if (checkResult.direction == SyncDirection.conflict) {
        // 有冲突，需要用户选择
        setState(() {
          _isSyncing = false;
          _subtitleText = '检测到数据差异';
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
              _subtitleText = progress;
            });
          }
        },
      );

      setState(() {
        _isSyncing = false;
        if (success) {
          _subtitleText = '同步完成';
        } else {
          _subtitleText = '同步失败，使用本地数据';
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
      print('[SplashPage] 同步检查失败: $e');
      setState(() {
        _isSyncing = false;
        _subtitleText = '同步检查失败，使用本地数据';
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
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.upload),
            child: Text('使用本地数据\n(覆盖云端)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.download),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('下载云端数据\n(推荐)'),
          ),
        ],
      ),
    );

    await _handleSyncAction(action);
  }

  /// 显示冲突对话框
  Future<void> _showConflictDialog(SyncCheckResult checkResult) async {
    if (!mounted) return;

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
            if (checkResult.conflict != null) ...[
              Text('本地文件: ${_formatDateTime(checkResult.conflict!.localModified)}'),
              Text('文件大小: ${_formatFileSize(checkResult.conflict!.localSize)}'),
              const SizedBox(height: 8),
              Text('服务器文件: ${_formatDateTime(checkResult.conflict!.remoteModified)}'),
              Text('文件大小: ${_formatFileSize(checkResult.conflict!.remoteSize)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.none),
            child: const Text('跳过同步'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.download),
            child: const Text('使用服务器数据'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(SyncDirection.upload),
            child: const Text('使用本地数据'),
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
        _syncProgress = action == SyncDirection.download ? '正在下载服务器数据...' : '正在上传本地数据...';
        _subtitleText = _syncProgress;
      });

      final success = await AutoSyncService.forcSync(ref, action);
      
      setState(() {
        _isSyncing = false;
        _subtitleText = success ? '同步完成' : '同步失败';
        _hasSyncError = !success;
      });
    } else {
      setState(() {
        _subtitleText = '跳过同步，使用本地数据';
      });
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
