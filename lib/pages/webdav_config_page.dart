import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_sync_service.dart';
import '../services/webdav_config.dart';
import '../services/auto_sync_service.dart';
import '../utils/global_refresh_service.dart';
import '../components/sync_status_widget.dart';
import '../utils/file_time_utils.dart';
import '../utils/sync_dialog_helper.dart';

enum ConflictAction {
  cancel,
  overwriteLocal,
  overwriteRemote,
}

class WebdavConfigPage extends ConsumerStatefulWidget {
  const WebdavConfigPage({super.key});

  @override
  ConsumerState<WebdavConfigPage> createState() => _WebdavConfigPageState();
}

class _WebdavConfigPageState extends ConsumerState<WebdavConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  String _syncStatus = '';

  // 新增：状态信息
  SyncStatusInfo _statusInfo = const SyncStatusInfo();
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadWebdavConfig();
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadWebdavConfig() async {
    final config = await WebDAVConfig.load();
    setState(() {
      // 如果没有配置，默认使用坚果云WebDAV地址
      _urlController.text =
          config.url.isEmpty ? 'https://dav.jianguoyun.com/dav/' : config.url;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
    });
  }

  Future<void> _saveWebdavConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查是否为首次配置（保存前先获取当前配置）
      final previousConfig = await WebDAVConfig.load();
      final isFirstTimeConfig = !previousConfig.isValid;

      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      await config.save();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebDAV配置已保存'),
            backgroundColor: Colors.green,
          ),
        );

        // 配置保存后立即更新同步状态
        await _loadSyncStatus();

        // 如果是首次配置，弹出初始同步选择对话框
        if (isFirstTimeConfig) {
          _showInitialSyncDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查是否为首次配置（测试前先获取当前配置）
      final previousConfig = await WebDAVConfig.load();
      final isFirstTimeConfig = !previousConfig.isValid;

      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final webdavClient = config.createClient();
      final success = await webdavClient.testConnection();

      if (mounted) {
        if (success) {
          // 测试成功后自动保存配置
          await config.save();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('连接测试成功，配置已保存'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // 保存成功后立即更新同步状态
          await _loadSyncStatus();

          // 如果是首次配置，弹出初始同步选择对话框
          if (isFirstTimeConfig) {
            _showInitialSyncDialog();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('连接测试失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接测试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });

    try {
      final config = await WebDAVConfig.load();
      if (!config.isValid) {
        setState(() {
          _statusInfo = const SyncStatusInfo(
            statusMessage: '请先配置WebDAV服务器',
            statusTitle: '未配置',
          );
          _isLoadingStatus = false;
        });
        return;
      }

      // 使用 AutoSyncService 的分析逻辑
      final syncCheckResult = await AutoSyncService.checkStartupSync();

      // 获取文件时间和大小信息用于显示
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      // 获取本地数据库文件时间和大小
      final databasePath = await syncService.getDatabaseFilePath();
      final localTime = await FileTimeUtils.getLocalDatabaseTime(databasePath);
      int? localSize;
      if (localTime != null) {
        final dbFile = await syncService.getDatabaseFile();
        final stat = await dbFile.stat();
        localSize = stat.size;
      }

      // 获取服务器文件信息
      DateTime? remoteTime;
      int? remoteSize;
      try {
        final remoteFileInfo =
            await webdavClient.getFileInfo(syncService.remoteDatabasePath);
        if (remoteFileInfo != null) {
          remoteTime = remoteFileInfo.lastModified;
          remoteSize = remoteFileInfo.size;
        }
      } catch (e) {
        AppLogger.debug('[WebdavConfig] 获取服务器文件信息失败: $e');
      }

      // 获取上次同步时间
      final lastSyncTime = await syncService.getLastSyncTime();

      // 根据 AutoSyncService 的分析结果确定状态标题
      String statusTitle = '同步状态';
      switch (syncCheckResult.direction) {
        case SyncDirection.download:
          statusTitle = '服务器有新数据';
          break;
        case SyncDirection.upload:
          statusTitle = '本地有未同步更改';
          break;
        case SyncDirection.conflict:
          statusTitle = '检测到同步冲突';
          break;
        case SyncDirection.none:
          statusTitle = '数据已同步';
          break;
      }

      setState(() {
        _statusInfo = SyncStatusInfo(
          localFileTime: localTime,
          remoteFileTime: remoteTime,
          lastSyncTime: lastSyncTime,
          localFileSize: localSize,
          remoteFileSize: remoteSize,
          statusMessage: syncCheckResult.hasError
              ? syncCheckResult.errorMessage ?? '检查失败'
              : syncCheckResult.message,
          statusTitle: statusTitle,
        );
        _isLoadingStatus = false;
      });
    } catch (e) {
      setState(() {
        _statusInfo = SyncStatusInfo(
          statusMessage: '获取同步状态失败: $e',
          statusTitle: '检查失败',
        );
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _uploadDatabase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showConfirmDialog(
      '确认上传',
      '将本地数据库上传到服务器？这将覆盖服务器上的数据。',
    );

    if (!confirmed) return;

    setState(() {
      _isSyncing = true;
      _syncStatus = '正在上传...';
    });

    try {
      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);
      final result = await syncService.uploadDatabase();

      if (result.conflict != null) {
        final action = await _showConflictDialog(result.conflict!);
        if (action == ConflictAction.cancel) {
          setState(() {
            _syncStatus = '上传已取消';
          });
          return;
        } else if (action == ConflictAction.overwriteRemote) {
          // 强制上传本地版本到服务器
          final forceResult =
              await syncService.uploadDatabase(forceOverwrite: true);
          setState(() {
            _syncStatus = forceResult.message;
            if (forceResult.success) {}
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(forceResult.message),
                backgroundColor:
                    forceResult.success ? Colors.green : Colors.red,
              ),
            );
          }

          if (forceResult.success) {
            await _loadSyncStatus();
          }
          return;
        }
      }

      setState(() {
        _syncStatus = result.message;
        if (result.success) {}
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }

      if (result.success) {
        await _loadSyncStatus();
      }
    } catch (e) {
      setState(() {
        _syncStatus = '上传失败: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _downloadDatabase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showConfirmDialog(
      '确认下载',
      '从服务器下载数据库？这将覆盖本地数据，建议先备份当前数据。',
    );

    if (!confirmed) return;

    final startTime = DateTime.now();
    AppLogger.debug('[WebdavConfig] 开始下载数据库 - ${startTime.toIso8601String()}');

    setState(() {
      _isSyncing = true;
      _syncStatus = '正在连接服务器...';
    });

    try {
      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      setState(() {
        _syncStatus = '正在检查远程文件...';
      });

      final downloadStartTime = DateTime.now();
      AppLogger.debug(
          '[WebdavConfig] 开始调用 downloadDatabase - ${downloadStartTime.toIso8601String()}');

      final result = await syncService.downloadDatabase(
        onProgress: (status) {
          setState(() {
            _syncStatus = status;
          });
        },
      );

      final downloadEndTime = DateTime.now();
      final downloadDuration = downloadEndTime.difference(downloadStartTime);
      AppLogger.debug(
          '[WebdavConfig] downloadDatabase 完成，耗时: ${downloadDuration.inMilliseconds}ms');

      if (result.conflict != null) {
        final action = await _showConflictDialog(result.conflict!);
        if (action == ConflictAction.cancel) {
          setState(() {
            _syncStatus = '下载已取消';
          });
          return;
        } else if (action == ConflictAction.overwriteLocal) {
          // 强制下载服务器版本覆盖本地
          final forceDownloadStartTime = DateTime.now();
          AppLogger.debug(
              '[WebdavConfig] 开始强制下载服务器版本 - ${forceDownloadStartTime.toIso8601String()}');

          setState(() {
            _syncStatus = '正在强制下载服务器版本...';
          });

          final forceResult = await syncService.downloadDatabase(
            forceOverwrite: true,
            onProgress: (status) {
              setState(() {
                _syncStatus = status;
              });
            },
          );

          final forceDownloadEndTime = DateTime.now();
          final forceDownloadDuration =
              forceDownloadEndTime.difference(forceDownloadStartTime);
          AppLogger.debug(
              '[WebdavConfig] 强制下载完成，耗时: ${forceDownloadDuration.inMilliseconds}ms');

          setState(() {
            _syncStatus = forceResult.message;
            if (forceResult.success) {}
          });

          if (forceResult.success) {
            await _loadSyncStatus();

            // 重新初始化数据库连接并刷新所有数据
            try {
              final refreshStartTime = DateTime.now();
              AppLogger.debug(
                  '[WebdavConfig] 开始刷新应用数据 - ${refreshStartTime.toIso8601String()}');

              setState(() {
                _syncStatus = '正在刷新应用数据...';
              });

              // 使用完整的数据库刷新，因为文件已被替换
              GlobalRefreshService.refreshAllData(ref);

              final refreshEndTime = DateTime.now();
              final refreshDuration =
                  refreshEndTime.difference(refreshStartTime);
              AppLogger.debug(
                  '[WebdavConfig] 应用数据刷新完成，耗时: ${refreshDuration.inMilliseconds}ms');

              final totalDuration = refreshEndTime.difference(startTime);
              AppLogger.debug(
                  '[WebdavConfig] 整个强制下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

              setState(() {
                _syncStatus =
                    '数据库同步完成，应用数据已刷新 (总耗时: ${totalDuration.inMilliseconds}ms)';
              });
            } catch (e) {
              AppLogger.debug('[WebdavConfig] 数据刷新失败: $e');
              setState(() {
                _syncStatus = '数据刷新失败: $e';
              });
            }
          }
          return;
        } else if (action == ConflictAction.overwriteRemote) {
          // 使用本地版本覆盖服务器
          final uploadStartTime = DateTime.now();
          AppLogger.debug(
              '[WebdavConfig] 开始上传本地版本覆盖服务器 - ${uploadStartTime.toIso8601String()}');

          setState(() {
            _syncStatus = '正在上传本地版本覆盖服务器...';
          });

          final uploadResult =
              await syncService.uploadDatabase(forceOverwrite: true);

          final uploadEndTime = DateTime.now();
          final uploadDuration = uploadEndTime.difference(uploadStartTime);
          AppLogger.debug(
              '[WebdavConfig] 上传完成，耗时: ${uploadDuration.inMilliseconds}ms');

          setState(() {
            _syncStatus = uploadResult.message;
            if (uploadResult.success) {}
          });

          if (uploadResult.success) {
            await _loadSyncStatus();
          }

          final totalDuration = uploadEndTime.difference(startTime);
          AppLogger.debug(
              '[WebdavConfig] 整个上传覆盖流程完成，总耗时: ${totalDuration.inMilliseconds}ms');
          return;
        }
      }

      setState(() {
        _syncStatus = result.message;
        if (result.success) {}
      });

      if (result.success) {
        await _loadSyncStatus();

        // 重新初始化数据库连接并刷新所有数据
        try {
          final refreshStartTime = DateTime.now();
          AppLogger.debug(
              '[WebdavConfig] 开始刷新应用数据 - ${refreshStartTime.toIso8601String()}');

          setState(() {
            _syncStatus = '正在刷新应用数据...';
          });

          // 使用完整的数据库刷新，因为文件已被替换
          GlobalRefreshService.refreshAllData(ref);

          final refreshEndTime = DateTime.now();
          final refreshDuration = refreshEndTime.difference(refreshStartTime);
          AppLogger.debug(
              '[WebdavConfig] 应用数据刷新完成，耗时: ${refreshDuration.inMilliseconds}ms');

          final totalDuration = refreshEndTime.difference(startTime);
          AppLogger.debug(
              '[WebdavConfig] 整个下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

          setState(() {
            _syncStatus =
                '数据库同步完成，应用数据已刷新 (总耗时: ${totalDuration.inMilliseconds}ms)';
          });
        } catch (e) {
          AppLogger.debug('[WebdavConfig] 数据刷新失败: $e');
          setState(() {
            _syncStatus = '数据刷新失败: $e';
          });
        }
      }
    } catch (e) {
      final errorEndTime = DateTime.now();
      final errorDuration = errorEndTime.difference(startTime);
      AppLogger.debug(
          '[WebdavConfig] 下载失败，总耗时: ${errorDuration.inMilliseconds}ms，错误: $e');

      setState(() {
        _syncStatus = '下载失败: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });

      final finalEndTime = DateTime.now();
      final finalDuration = finalEndTime.difference(startTime);
      AppLogger.debug(
          '[WebdavConfig] 下载操作结束，总耗时: ${finalDuration.inMilliseconds}ms');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showInitialSyncDialog() async {
    // 首先进行同步检查以获取智能建议
    final syncCheckResult = await AutoSyncService.checkStartupSync();

    if (!mounted) return; // 检查组件是否仍然挂载

    // 使用统一的推荐信息
    final syncRecommendation =
        SyncDialogHelper.getSyncRecommendation(syncCheckResult.direction);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) => AlertDialog(
        title: const Text('初始同步'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WebDAV配置已完成！请选择如何进行初始数据同步：'),
            const SizedBox(height: 16),

            // 显示当前同步状态
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
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncCheckResult.message,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 显示智能建议
            if (syncRecommendation.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              SyncDialogHelper.buildRecommendationContainer(
                message: syncRecommendation.message,
                color: syncRecommendation.color,
                icon: syncRecommendation.icon,
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              '• 下载：从服务器获取数据到本地\n'
              '• 上传：将本地数据上传到服务器\n'
              '• 跳过：稍后手动同步',
              style: TextStyle(fontSize: 13),
            ),

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
                      '⚠️ 重要提醒：\n'
                      '• 下载将覆盖本地所有数据\n'
                      '• 上传将覆盖服务器所有数据\n'
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
                          TextSpan(text: '• 点击“上传”将覆盖服务器数据\n'),
                          TextSpan(text: '• 点击“下载”将覆盖本地数据\n\n'),
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
            onPressed: () => Navigator.of(context).pop('skip'),
            child: const Text('跳过'),
          ),
          // 上传按钮 - 使用统一样式
          SyncDialogHelper.buildInitialSyncButton(
            text: '上传',
            onPressed: () => Navigator.of(context).pop('upload'),
            recommendation: syncCheckResult.direction,
            buttonType: SyncDirection.upload,
            icon: Icons.cloud_upload,
          ),
          const SizedBox(width: 8),
          // 下载按钮 - 使用统一样式
          SyncDialogHelper.buildInitialSyncButton(
            text: '下载',
            onPressed: () => Navigator.of(context).pop('download'),
            recommendation: syncCheckResult.direction,
            buttonType: SyncDirection.download,
            icon: Icons.cloud_download,
          ),
        ],
      ),
    );

    // 根据用户选择执行相应操作
    if (result != null && result != 'skip') {
      if (result == 'download') {
        await _downloadDatabase();
      } else if (result == 'upload') {
        await _uploadDatabase();
      }
    }
  }

  Future<ConflictAction> _showConflictDialog(SyncConflict conflict) async {
    // 使用统一的冲突推荐逻辑
    final recommendation = SyncDialogHelper.getConflictRecommendation(conflict);

    final result = await showDialog<ConflictAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('检测到冲突'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本地和服务器的数据都有更新，请选择如何处理：'),
            const SizedBox(height: 16),

            // 文件信息对比 - 使用统一样式
            SyncDialogHelper.buildFileInfoContainer(
              conflict: conflict,
              localIsNewerChecker: (c) =>
                  c.localModified.isAfter(c.remoteModified),
              remoteIsNewerChecker: (c) =>
                  c.remoteModified.isAfter(c.localModified),
              dateFormatter: _formatDateTime,
              sizeFormatter: _formatFileSize,
            ),

            // 智能建议 - 使用统一样式
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ConflictAction.cancel),
            child: const Text('取消'),
          ),
          // 服务器版本按钮 - 使用统一样式
          SyncDialogHelper.buildConflictButton(
            text: '使用服务器版本',
            onPressed: () =>
                Navigator.of(context).pop(ConflictAction.overwriteLocal),
            isRecommended: recommendation.recommendedAction ==
                ConflictButtonType.useRemote,
            buttonType: ConflictButtonType.useRemote,
          ),
          const SizedBox(width: 8),
          // 本地版本按钮 - 使用统一样式
          SyncDialogHelper.buildConflictButton(
            text: '使用本地版本',
            onPressed: () =>
                Navigator.of(context).pop(ConflictAction.overwriteRemote),
            isRecommended:
                recommendation.recommendedAction == ConflictButtonType.useLocal,
            buttonType: ConflictButtonType.useLocal,
            isElevated: true,
          ),
        ],
      ),
    );
    return result ?? ConflictAction.cancel;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        title: const Text(
          'WebDAV配置',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFFF5F6FB),
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWebdavConfig,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // WebDAV配置卡片
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WebDAV服务器配置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'WebDAV URL',
                            hintText: 'https://dav.jianguoyun.com/dav/',
                            prefixIcon: Icon(Icons.link, size: 20),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6.0)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelStyle: TextStyle(fontSize: 14),
                            hintStyle: TextStyle(fontSize: 14),
                            helperText: '⚠️ 注意：URL末尾必须带斜杠 /',
                            helperStyle:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入WebDAV URL';
                            }
                            final trimmedValue = value.trim();
                            final uri = Uri.tryParse(trimmedValue);
                            if (uri == null || !uri.hasAbsolutePath) {
                              return '请输入有效的URL';
                            }
                            if (!trimmedValue.endsWith('/')) {
                              return 'WebDAV URL末尾必须带斜杠 / ，例如：https://dav.jianguoyun.com/dav/';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person, size: 20),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6.0)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelStyle: TextStyle(fontSize: 14),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6.0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelStyle: const TextStyle(fontSize: 14),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '连接测试',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConnection,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.wifi_protected_setup),
                            label: Text(_isLoading ? '测试中...' : '测试连接'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 合并同步状态和同步操作卡片
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '数据同步',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 同步状态组件
                        SyncStatusWidget(
                          statusInfo:
                              _statusInfo.copyWith(isLoading: _isLoadingStatus),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '同步操作',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _isSyncing)
                                    ? null
                                    : _uploadDatabase,
                                icon: _isSyncing && _syncStatus.contains('上传')
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload),
                                label: Text(
                                    _isSyncing && _syncStatus.contains('上传')
                                        ? '上传中...'
                                        : '上传到服务器'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _isSyncing)
                                    ? null
                                    : _downloadDatabase,
                                icon: _isSyncing && _syncStatus.contains('下载')
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_download),
                                label: Text(
                                    _isSyncing && _syncStatus.contains('下载')
                                        ? '下载中...'
                                        : '从服务器下载'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isSyncing && _syncStatus.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _syncStatus.contains('上传')
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _syncStatus,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 使用说明卡片
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '使用说明',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(text: '• WebDAV URL: 您的WebDAV服务器地址\n'),
                              TextSpan(
                                text:
                                    '  ⚠️ URL末尾必须带斜杠 /，如 https://dav.jianguoyun.com/dav/',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: '\n\n• 用户名: WebDAV服务器的登录用户名\n'),
                              TextSpan(text: '• 密码: WebDAV服务器的登录密码\n'),
                              TextSpan(text: '• 配置完成后可以使用测试连接验证设置是否正确\n\n'),
                              TextSpan(
                                text: '🌰 推荐服务商：\n',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                  text:
                                      '• 坚果云: https://dav.jianguoyun.com/dav/\n'),
                              TextSpan(text: '• 其他支持WebDAV的云存储服务'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
