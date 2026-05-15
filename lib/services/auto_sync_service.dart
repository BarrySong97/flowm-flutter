import 'package:flowm/shared/logging/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watcher/watcher.dart';
import '../services/database_sync_service.dart';
import '../services/webdav_config.dart';
import '../services/network_service.dart';
import '../utils/file_time_utils.dart';
import '../utils/global_refresh_service.dart';
import '../services/sync_analyzer.dart';
import '../models/sync_record.dart';
import '../components/conflict_dialog.dart';
import '../navigation/app_router.dart';

/// 同步检查结果类
class SyncCheckResult {
  final bool shouldSync;
  final SyncDirection direction;
  final String message;
  final SyncConflict? conflict;
  final bool hasError;
  final String? errorMessage;

  const SyncCheckResult({
    required this.shouldSync,
    required this.direction,
    required this.message,
    this.conflict,
    this.hasError = false,
    this.errorMessage,
  });

  factory SyncCheckResult.noSync(String message) {
    return SyncCheckResult(
      shouldSync: false,
      direction: SyncDirection.none,
      message: message,
    );
  }

  factory SyncCheckResult.download(String message) {
    return SyncCheckResult(
      shouldSync: true,
      direction: SyncDirection.download,
      message: message,
    );
  }

  factory SyncCheckResult.upload(String message) {
    return SyncCheckResult(
      shouldSync: true,
      direction: SyncDirection.upload,
      message: message,
    );
  }

  factory SyncCheckResult.conflict(SyncConflict conflict) {
    return SyncCheckResult(
      shouldSync: true,
      direction: SyncDirection.conflict,
      message: '检测到同步冲突',
      conflict: conflict,
    );
  }

  factory SyncCheckResult.error(String errorMessage) {
    return SyncCheckResult(
      shouldSync: false,
      direction: SyncDirection.none,
      message: '检查失败',
      hasError: true,
      errorMessage: errorMessage,
    );
  }
}

/// 同步方向枚举
enum SyncDirection {
  none, // 不需要同步
  download, // 从服务器下载
  upload, // 上传到服务器
  conflict, // 有冲突需要用户选择
}

/// 全局同步管理器
class AutoSyncService {
  // 同步状态管理
  static bool _isSyncing = false;
  static Timer? _uploadTimer;
  static Timer? _dbWatcher; // 保留作为回退机制
  static DateTime? _lastSyncCheck;

  // 文件系统监听器
  static DirectoryWatcher? _fileWatcher;
  static StreamSubscription? _watcherSubscription;

  // 防抖延迟时间（秒）
  static const int _debounceDelaySeconds = 3;

  // 同步超时时间（秒）
  static const int _syncTimeoutSeconds = 10;

  /// 检查是否正在同步
  static bool get isSyncing => _isSyncing;

  /// 场景A：启动时检查是否需要同步
  static Future<SyncCheckResult> checkStartupSync() async {
    final startTime = DateTime.now();
    AppLogger.debug(
        '[AutoSyncService] 开始启动时同步检查 - ${startTime.toIso8601String()}');

    try {
      // 检查WebDAV配置
      final config = await WebDAVConfig.load();
      if (!config.isValid) {
        return SyncCheckResult.noSync('未配置WebDAV服务器');
      }

      // 创建同步服务
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      // 检查是否曾经同步过
      final hasEverSynced = await _hasEverSynced();

      // 如果从未同步过，记录状态后继续使用现有智能判断流程
      if (!hasEverSynced) {
        AppLogger.debug('[AutoSyncService] 检测到从未同步过，进入首次配置处理');
      }

      // 分析同步需求
      final result = await _analyzeSyncNeed(syncService);

      final duration = DateTime.now().difference(startTime);
      AppLogger.debug(
          '[AutoSyncService] 启动时同步检查完成，耗时: ${duration.inMilliseconds}ms，结果: ${result.message}');

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.debug(
          '[AutoSyncService] 启动时同步检查失败，耗时: ${duration.inMilliseconds}ms，错误: $e');

      return SyncCheckResult.error('同步检查失败: $e');
    }
  }

  /// 分析同步需求（基于 ETag/Hash）
  static Future<SyncCheckResult> _analyzeSyncNeed(
    DatabaseSyncService syncService,
  ) async {
    try {
      AppLogger.debug('[AutoSyncService] 开始基于 ETag/Hash 的同步分析');

      // 1. 获取本地文件哈希
      String? currentLocalHash;
      try {
        final dbFile = await syncService.getDatabaseFile();
        if (await dbFile.exists()) {
          currentLocalHash = await syncService.calculateFileHash(dbFile);
          AppLogger.debug('[AutoSyncService] 本地文件哈希: $currentLocalHash');
        } else {
          AppLogger.debug('[AutoSyncService] 本地文件不存在');
        }
      } catch (e) {
        AppLogger.debug('[AutoSyncService] 获取本地文件哈希失败: $e');
      }

      // 2. 获取远程文件信息
      RemoteSyncInfo? currentRemoteInfo;
      try {
        final remoteFileInfo = await syncService.webdavClient
            .getFileInfo(syncService.remoteDatabasePath);
        if (remoteFileInfo != null) {
          currentRemoteInfo = RemoteSyncInfo.fromWebDAVFileInfo(remoteFileInfo);
          AppLogger.debug('[AutoSyncService] 远程文件信息: $currentRemoteInfo');
        } else {
          AppLogger.debug('[AutoSyncService] 远程文件不存在');
        }
      } catch (e) {
        AppLogger.debug('[AutoSyncService] 获取远程文件信息失败: $e');
      }

      // 3. 获取上次同步记录
      final lastSyncRecord = await WebDAVConfig.getSyncRecord();
      AppLogger.debug('[AutoSyncService] 上次同步记录: $lastSyncRecord');

      // 4. 使用同步分析器进行分析
      final decision = await SyncAnalyzer.analyzeSyncNeed(
        currentLocalHash: currentLocalHash,
        currentRemoteInfo: currentRemoteInfo,
        lastSyncRecord: lastSyncRecord,
        syncService: syncService,
      );

      // 5. 转换为 SyncCheckResult
      switch (decision) {
        case SyncDecision.noSync:
          return SyncCheckResult.noSync('数据已同步，无需操作');
        case SyncDecision.upload:
          return SyncCheckResult.upload('检测到本地数据更新，需要上传');
        case SyncDecision.download:
          return SyncCheckResult.download('检测到服务器数据更新，需要下载');
        case SyncDecision.conflict:
          // 构建冲突信息
          final conflict = await _buildConflictInfo(
              currentLocalHash, currentRemoteInfo, syncService);
          return SyncCheckResult.conflict(conflict);
      }
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 同步分析过程发生错误: $e');
      return SyncCheckResult.error('同步分析失败: $e');
    }
  }

  /// 构建冲突信息
  static Future<SyncConflict> _buildConflictInfo(
    String? localHash,
    RemoteSyncInfo? remoteInfo,
    DatabaseSyncService syncService,
  ) async {
    try {
      // 获取本地文件信息
      final dbFile = await syncService.getDatabaseFile();
      final localStat = await dbFile.stat();

      // 获取远程哈希（如果是 ETag，需要下载文件计算）
      String remoteHash = 'unknown';
      if (remoteInfo?.anchor.type == SyncAnchorType.hash) {
        remoteHash = remoteInfo!.anchor.value;
      } else if (remoteInfo?.anchor.type == SyncAnchorType.etag) {
        try {
          final remoteData = await syncService.webdavClient
              .downloadFile(syncService.remoteDatabasePath);
          remoteHash = md5.convert(remoteData).toString();
        } catch (e) {
          AppLogger.debug('[AutoSyncService] 获取远程文件哈希失败: $e');
        }
      }

      return SyncConflict(
        localModified: localStat.modified,
        remoteModified: remoteInfo?.lastModified ?? DateTime.now(),
        localSize: localStat.size,
        remoteSize: remoteInfo?.size ?? 0,
        localHash: localHash ?? 'unknown',
        remoteHash: remoteHash,
      );
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 构建冲突信息失败: $e');
      // 返回基本冲突信息
      return SyncConflict(
        localModified: DateTime.now(),
        remoteModified: DateTime.now(),
        localSize: 0,
        remoteSize: 0,
        localHash: localHash ?? 'unknown',
        remoteHash: 'unknown',
      );
    }
  }

  /// 执行启动时同步
  static Future<bool> executeStartupSync(
    SyncCheckResult checkResult,
    WidgetRef ref, {
    Function(String)? onProgress,
  }) async {
    if (!checkResult.shouldSync || _isSyncing) {
      return false;
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      AppLogger.debug(
          '[AutoSyncService] 开始执行启动时同步 - ${startTime.toIso8601String()}');

      final config = await WebDAVConfig.load();
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      bool success = false;

      switch (checkResult.direction) {
        case SyncDirection.download:
          onProgress?.call('正在从服务器下载最新数据...');
          final result = await syncService
              .downloadDatabase(
                forceOverwrite: false,
                onProgress: onProgress,
              )
              .timeout(Duration(seconds: _syncTimeoutSeconds));
          success = result.success;
          break;

        case SyncDirection.upload:
          onProgress?.call('正在上传本地数据到服务器...');
          final result = await syncService
              .uploadDatabase(
                forceOverwrite: false,
              )
              .timeout(Duration(seconds: _syncTimeoutSeconds));
          success = result.success;
          break;

        case SyncDirection.conflict:
          // 冲突情况需要用户选择，这里返回false让调用者处理
          return false;

        case SyncDirection.none:
          return true;
      }

      if (success && checkResult.direction == SyncDirection.download) {
        // 下载成功后刷新应用数据
        onProgress?.call('正在刷新应用数据...');
        await GlobalRefreshService.refreshDatabaseFile(ref);
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.debug(
          '[AutoSyncService] 启动时同步完成，耗时: ${duration.inMilliseconds}ms，成功: $success');

      return success;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.debug(
          '[AutoSyncService] 启动时同步失败，耗时: ${duration.inMilliseconds}ms，错误: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// 场景B：开始监听数据库变化（运行时自动上传）
  static void startDatabaseWatcher(WidgetRef ref) {
    if (_fileWatcher != null || _dbWatcher != null) {
      return; // 已经在监听
    }

    AppLogger.debug('[AutoSyncService] 开始监听数据库文件变化');

    // 开始网络状态监控
    NetworkService.initialize();

    // 尝试启动文件系统监听，失败则回退到定时检查
    _startFileSystemWatcher(ref);
  }

  /// 启动文件系统监听器
  static Future<void> _startFileSystemWatcher(WidgetRef ref) async {
    try {
      // 获取WebDAV配置来创建同步服务
      final config = await WebDAVConfig.load();
      if (!config.isValid) {
        AppLogger.debug('[AutoSyncService] WebDAV未配置，跳过文件监听');
        return;
      }

      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);
      final databasePath = await syncService.getDatabaseFilePath();
      final dbFile = File(databasePath);
      final dbDirectory = dbFile.parent;

      AppLogger.debug('[AutoSyncService] 启动文件系统监听: ${dbDirectory.path}');

      _fileWatcher = DirectoryWatcher(dbDirectory.path);
      _watcherSubscription = _fileWatcher!.events
          .where((event) =>
              event.path.endsWith('.sqlite') && event.type == ChangeType.MODIFY)
          .listen((event) {
        AppLogger.debug('[AutoSyncService] 检测到数据库文件变化: ${event.path}');
        scheduleUpload(ref);
      }, onError: (error) {
        AppLogger.debug('[AutoSyncService] 文件监听器错误: $error，切换到定时检查');
        _fallbackToPeriodicCheck(ref);
      });

      AppLogger.debug('[AutoSyncService] 文件系统监听已启动');
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 文件系统监听启动失败: $e，使用定时检查作为回退');
      _fallbackToPeriodicCheck(ref);
    }
  }

  /// 回退到定时检查机制
  static void _fallbackToPeriodicCheck(WidgetRef ref) {
    // 清理文件监听器
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _fileWatcher = null;

    // 启动定时检查作为回退机制
    if (_dbWatcher == null) {
      AppLogger.debug('[AutoSyncService] 启动定时检查回退机制（30秒轮询）');
      _dbWatcher = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkDatabaseChanges(ref);
      });
    }
  }

  /// 检查数据库变化
  static void _checkDatabaseChanges(WidgetRef ref) async {
    try {
      final config = await WebDAVConfig.load();
      if (!config.isValid || _isSyncing) {
        return;
      }

      // 检查网络状态
      if (!NetworkService.isOnline) {
        AppLogger.debug('[AutoSyncService] 网络离线，跳过数据库变化检查');
        return;
      }

      final syncService =
          DatabaseSyncService(webdavClient: config.createClient());
      final databasePath = await syncService.getDatabaseFilePath();
      final currentTime =
          await FileTimeUtils.getLocalDatabaseTime(databasePath);

      if (currentTime != null && _lastSyncCheck != null) {
        if (currentTime.isAfter(_lastSyncCheck!)) {
          AppLogger.debug('[AutoSyncService] 检测到数据库变化，准备上传');
          scheduleUpload(ref);
        }
      }

      _lastSyncCheck = currentTime;
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 检查数据库变化失败: $e');
    }
  }

  /// 防抖上传
  static void scheduleUpload(WidgetRef ref) {
    // 取消之前的定时器
    _uploadTimer?.cancel();

    AppLogger.debug('[AutoSyncService] 安排防抖上传，延迟 $_debounceDelaySeconds 秒');

    // 设置新的定时器
    _uploadTimer = Timer(Duration(seconds: _debounceDelaySeconds), () {
      _executeBackgroundUpload(ref);
    });
  }

  /// 执行后台上传
  static void _executeBackgroundUpload(WidgetRef ref) async {
    if (_isSyncing) {
      return;
    }

    // 检查网络状态
    if (!NetworkService.isOnline) {
      AppLogger.debug('[AutoSyncService] 网络离线，跳过后台上传');
      return;
    }

    _isSyncing = true;

    try {
      AppLogger.debug('[AutoSyncService] 开始执行后台上传');

      final config = await WebDAVConfig.load();
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      final result = await syncService.uploadDatabase(forceOverwrite: false);

      if (result.conflict != null) {
        AppLogger.debug('[AutoSyncService] 后台上传检测到冲突，显示对话框让用户选择');

        // 使用全局上下文显示冲突对话框（使用启动模式避免Overlay问题）
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final action = await ConflictDialogService.showConflictDialog(
            context,
            result.conflict!,
            isStartup: true, // 使用启动模式，避免Overlay依赖
          );

          if (context.mounted) {
            await _handleConflictAction(action, syncService, ref);
          }
        } else {
          AppLogger.debug('[AutoSyncService] 无法获取有效上下文，跳过冲突处理');
        }
      } else if (result.success) {
        AppLogger.debug('[AutoSyncService] 后台上传成功');
      } else {
        AppLogger.debug('[AutoSyncService] 后台上传失败: ${result.message}');
      }
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 后台上传异常: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 处理冲突用户选择
  static Future<void> _handleConflictAction(
    ConflictAction? action,
    DatabaseSyncService syncService,
    WidgetRef ref,
  ) async {
    if (action == null || action == ConflictAction.cancel) {
      AppLogger.debug('[AutoSyncService] 用户取消冲突处理');
      return;
    }

    try {
      if (action == ConflictAction.useLocal) {
        AppLogger.debug('[AutoSyncService] 用户选择使用本地版本，强制上传');
        final uploadResult =
            await syncService.uploadDatabase(forceOverwrite: true);
        if (uploadResult.success) {
          AppLogger.debug('[AutoSyncService] 强制上传成功');
        } else {
          AppLogger.debug('[AutoSyncService] 强制上传失败: ${uploadResult.message}');
        }
      } else if (action == ConflictAction.useRemote) {
        AppLogger.debug('[AutoSyncService] 用户选择使用服务器版本，下载覆盖本地');
        final downloadResult =
            await syncService.downloadDatabase(forceOverwrite: true);
        if (downloadResult.success) {
          AppLogger.debug('[AutoSyncService] 下载覆盖成功，刷新应用数据');
          // 刷新应用数据，因为本地数据库文件被替换了
          GlobalRefreshService.refreshAllData(ref);
        } else {
          AppLogger.debug(
              '[AutoSyncService] 下载覆盖失败: ${downloadResult.message}');
        }
      }
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 处理冲突选择时发生异常: $e');
    }
  }

  /// 停止监听
  static void stopWatcher() {
    AppLogger.debug('[AutoSyncService] 停止数据库文件监听');

    // 停止文件系统监听
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _fileWatcher = null;

    // 停止定时检查
    _dbWatcher?.cancel();
    _dbWatcher = null;

    // 停止上传定时器
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // 停止网络状态监控
    NetworkService.dispose();
  }

  /// 检查是否曾经同步过
  static Future<bool> _hasEverSynced() async {
    try {
      // 检查本地是否有同步历史记录
      final lastSyncTime = await WebDAVConfig.getLastSyncTime();
      final lastLocalHash = await WebDAVConfig.getLastLocalHash();
      final lastRemoteHash = await WebDAVConfig.getLastRemoteHash();

      // 如果有任何同步记录，说明曾经同步过
      return lastSyncTime != null ||
          lastLocalHash != null ||
          lastRemoteHash != null;
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 检查同步历史失败: $e');
      // 如果检查失败，保守地认为从未同步过
      return false;
    }
  }

  /// 强制同步（用户手动触发）
  static Future<bool> forcSync(WidgetRef ref, SyncDirection direction) async {
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;

    try {
      final config = await WebDAVConfig.load();
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      bool success = false;

      switch (direction) {
        case SyncDirection.download:
          final result =
              await syncService.downloadDatabase(forceOverwrite: true);
          success = result.success;
          if (success) {
            await GlobalRefreshService.refreshDatabaseFile(ref);
          }
          break;

        case SyncDirection.upload:
          final result = await syncService.uploadDatabase(forceOverwrite: true);
          success = result.success;
          break;

        default:
          return false;
      }

      AppLogger.debug('[AutoSyncService] 强制同步完成，方向: $direction，成功: $success');
      return success;
    } catch (e) {
      AppLogger.debug('[AutoSyncService] 强制同步失败: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
