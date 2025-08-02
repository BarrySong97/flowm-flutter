import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_sync_service.dart';
import '../services/webdav_config.dart';
import '../utils/global_refresh_service.dart';
import '../components/sync_status_widget.dart';
import '../utils/file_time_utils.dart';

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
  DateTime? _lastSyncTime;
  
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
      _urlController.text = config.url;
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
        _loadSyncStatus();
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
      final config = WebDAVConfig(
        url: _urlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final webdavClient = config.createClient();
      final success = await webdavClient.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接测试成功' : '连接测试失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
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
          );
          _isLoadingStatus = false;
        });
        return;
      }

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
        final remoteFileInfo = await webdavClient.getFileInfo(syncService.remoteDatabasePath);
        if (remoteFileInfo != null) {
          remoteTime = remoteFileInfo.lastModified;
          remoteSize = remoteFileInfo.size;
        }
      } catch (e) {
        print('[WebdavConfig] 获取服务器文件信息失败: $e');
      }

      // 获取上次同步时间
      final lastSyncTime = await syncService.getLastSyncTime();

      setState(() {
        _statusInfo = SyncStatusInfo(
          localFileTime: localTime,
          remoteFileTime: remoteTime,
          lastSyncTime: lastSyncTime,
          localFileSize: localSize,
          remoteFileSize: remoteSize,
          statusMessage: _getSyncStatusMessage(localTime, remoteTime),
        );
        _lastSyncTime = lastSyncTime;
        _isLoadingStatus = false;
      });
    } catch (e) {
      setState(() {
        _statusInfo = SyncStatusInfo(
          statusMessage: '获取同步状态失败: $e',
        );
        _isLoadingStatus = false;
      });
    }
  }

  String _getSyncStatusMessage(DateTime? localTime, DateTime? remoteTime) {
    if (localTime == null && remoteTime == null) {
      return '未找到数据库文件';
    }
    if (localTime == null) {
      return '服务器有新数据，建议下载';
    }
    if (remoteTime == null) {
      return '本地有数据，建议上传到服务器';
    }

    final comparison = FileTimeUtils.compareTime(localTime, remoteTime);
    if (comparison > 0) {
      return '本地数据较新，建议上传';
    } else if (comparison < 0) {
      return '服务器数据较新，建议下载';
    } else {
      return '数据已同步';
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
          final forceResult = await syncService.uploadDatabase(forceOverwrite: true);
          setState(() {
            _syncStatus = forceResult.message;
            if (forceResult.success) {
              _lastSyncTime = forceResult.timestamp;
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(forceResult.message),
                backgroundColor: forceResult.success ? Colors.green : Colors.red,
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
        if (result.success) {
          _lastSyncTime = result.timestamp;
        }
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
    print('[WebdavConfig] 开始下载数据库 - ${startTime.toIso8601String()}');

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
      print('[WebdavConfig] 开始调用 downloadDatabase - ${downloadStartTime.toIso8601String()}');
      
      final result = await syncService.downloadDatabase(
        onProgress: (status) {
          setState(() {
            _syncStatus = status;
          });
        },
      );
      
      final downloadEndTime = DateTime.now();
      final downloadDuration = downloadEndTime.difference(downloadStartTime);
      print('[WebdavConfig] downloadDatabase 完成，耗时: ${downloadDuration.inMilliseconds}ms');

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
          print('[WebdavConfig] 开始强制下载服务器版本 - ${forceDownloadStartTime.toIso8601String()}');
          
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
          final forceDownloadDuration = forceDownloadEndTime.difference(forceDownloadStartTime);
          print('[WebdavConfig] 强制下载完成，耗时: ${forceDownloadDuration.inMilliseconds}ms');
          
          setState(() {
            _syncStatus = forceResult.message;
            if (forceResult.success) {
              _lastSyncTime = forceResult.timestamp;
            }
          });

          if (forceResult.success) {
            await _loadSyncStatus();

            // 重新初始化数据库连接并刷新所有数据
            try {
              final refreshStartTime = DateTime.now();
              print('[WebdavConfig] 开始刷新应用数据 - ${refreshStartTime.toIso8601String()}');
              
              setState(() {
                _syncStatus = '正在刷新应用数据...';
              });
              
              // 尝试使用实验性的轻量级刷新
              try {
                print('[WebdavConfig] 尝试轻量级数据刷新');
                await GlobalRefreshService.refreshDatabaseFile(ref);
                print('[WebdavConfig] 轻量级数据刷新成功');
              } catch (e) {
                print('[WebdavConfig] 轻量级刷新失败，使用完整刷新: $e');
                GlobalRefreshService.refreshAllData(ref);
              }
              
              final refreshEndTime = DateTime.now();
              final refreshDuration = refreshEndTime.difference(refreshStartTime);
              print('[WebdavConfig] 应用数据刷新完成，耗时: ${refreshDuration.inMilliseconds}ms');

              final totalDuration = refreshEndTime.difference(startTime);
              print('[WebdavConfig] 整个强制下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

              setState(() {
                _syncStatus = '数据库同步完成，应用数据已刷新 (总耗时: ${totalDuration.inMilliseconds}ms)';
              });
            } catch (e) {
              print('[WebdavConfig] 数据刷新失败: $e');
              setState(() {
                _syncStatus = '数据刷新失败: $e';
              });
            }
          }
          return;
        } else if (action == ConflictAction.overwriteRemote) {
          // 使用本地版本覆盖服务器
          final uploadStartTime = DateTime.now();
          print('[WebdavConfig] 开始上传本地版本覆盖服务器 - ${uploadStartTime.toIso8601String()}');
          
          setState(() {
            _syncStatus = '正在上传本地版本覆盖服务器...';
          });
          
          final uploadResult = await syncService.uploadDatabase(forceOverwrite: true);
          
          final uploadEndTime = DateTime.now();
          final uploadDuration = uploadEndTime.difference(uploadStartTime);
          print('[WebdavConfig] 上传完成，耗时: ${uploadDuration.inMilliseconds}ms');
          
          setState(() {
            _syncStatus = uploadResult.message;
            if (uploadResult.success) {
              _lastSyncTime = uploadResult.timestamp;
            }
          });

          if (uploadResult.success) {
            await _loadSyncStatus();
          }

          final totalDuration = uploadEndTime.difference(startTime);
          print('[WebdavConfig] 整个上传覆盖流程完成，总耗时: ${totalDuration.inMilliseconds}ms');
          return;
        }
      }

      setState(() {
        _syncStatus = result.message;
        if (result.success) {
          _lastSyncTime = result.timestamp;
        }
      });

      if (result.success) {
        await _loadSyncStatus();

        // 重新初始化数据库连接并刷新所有数据
        try {
          final refreshStartTime = DateTime.now();
          print('[WebdavConfig] 开始刷新应用数据 - ${refreshStartTime.toIso8601String()}');
          
          setState(() {
            _syncStatus = '正在刷新应用数据...';
          });
          
          // 尝试使用实验性的轻量级刷新
          try {
            print('[WebdavConfig] 尝试轻量级数据刷新');
            await GlobalRefreshService.refreshDatabaseFile(ref);
            print('[WebdavConfig] 轻量级数据刷新成功');
          } catch (e) {
            print('[WebdavConfig] 轻量级刷新失败，使用完整刷新: $e');
            GlobalRefreshService.refreshAllData(ref);
          }
          
          final refreshEndTime = DateTime.now();
          final refreshDuration = refreshEndTime.difference(refreshStartTime);
          print('[WebdavConfig] 应用数据刷新完成，耗时: ${refreshDuration.inMilliseconds}ms');
          
          final totalDuration = refreshEndTime.difference(startTime);
          print('[WebdavConfig] 整个下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

          setState(() {
            _syncStatus = '数据库同步完成，应用数据已刷新 (总耗时: ${totalDuration.inMilliseconds}ms)';
          });
        } catch (e) {
          print('[WebdavConfig] 数据刷新失败: $e');
          setState(() {
            _syncStatus = '数据刷新失败: $e';
          });
        }
      }
    } catch (e) {
      final errorEndTime = DateTime.now();
      final errorDuration = errorEndTime.difference(startTime);
      print('[WebdavConfig] 下载失败，总耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      
      setState(() {
        _syncStatus = '下载失败: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
      
      final finalEndTime = DateTime.now();
      final finalDuration = finalEndTime.difference(startTime);
      print('[WebdavConfig] 下载操作结束，总耗时: ${finalDuration.inMilliseconds}ms');
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

  Future<ConflictAction> _showConflictDialog(SyncConflict conflict) async {
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
            Text('本地文件: ${_formatDateTime(conflict.localModified)}'),
            Text('文件大小: ${_formatFileSize(conflict.localSize)}'),
            const SizedBox(height: 8),
            Text('服务器文件: ${_formatDateTime(conflict.remoteModified)}'),
            Text('文件大小: ${_formatFileSize(conflict.remoteSize)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ConflictAction.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictAction.overwriteLocal),
            child: const Text('使用服务器版本'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictAction.overwriteRemote),
            child: const Text('使用本地版本'),
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
        title: const Text('WebDAV配置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWebdavConfig,
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
                Card(
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'WebDAV URL',
                            hintText: 'https://example.com/webdav',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入WebDAV URL';
                            }
                            final uri = Uri.tryParse(value.trim());
                            if (uri == null || !uri.hasAbsolutePath) {
                              return '请输入有效的URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '操作',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 新的同步状态显示组件
                SyncStatusWidget(
                  statusInfo: _statusInfo.copyWith(isLoading: _isLoadingStatus),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '同步操作',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '说明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• WebDAV URL: 您的WebDAV服务器地址\n'
                          '• 用户名: WebDAV服务器的登录用户名\n'
                          '• 密码: WebDAV服务器的登录密码\n'
                          '• 配置完成后可以使用测试连接验证设置是否正确',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
