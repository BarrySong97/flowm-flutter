import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_sync_service.dart';
import '../services/webdav_config.dart';
import '../services/network_service.dart';
import '../utils/file_time_utils.dart';
import '../utils/global_refresh_service.dart';

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
  none,       // 不需要同步
  download,   // 从服务器下载
  upload,     // 上传到服务器
  conflict,   // 有冲突需要用户选择
}

/// 全局同步管理器
class AutoSyncService {
  // 同步状态管理
  static bool _isSyncing = false;
  static Timer? _uploadTimer;
  static Timer? _dbWatcher;
  static DateTime? _lastSyncCheck;
  
  // 防抖延迟时间（秒）
  static const int _debounceDelaySeconds = 3;
  
  // 同步超时时间（秒）
  static const int _syncTimeoutSeconds = 10;

  /// 检查是否正在同步
  static bool get isSyncing => _isSyncing;

  /// 场景A：启动时检查是否需要同步
  static Future<SyncCheckResult> checkStartupSync() async {
    final startTime = DateTime.now();
    print('[AutoSyncService] 开始启动时同步检查 - ${startTime.toIso8601String()}');

    try {
      // 检查WebDAV配置
      final config = await WebDAVConfig.load();
      if (!config.isValid) {
        return SyncCheckResult.noSync('未配置WebDAV服务器');
      }

      // 创建同步服务
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      // 获取本地数据库信息
      final databasePath = await syncService.getDatabaseFilePath();
      final localTime = await FileTimeUtils.getLocalDatabaseTime(databasePath);

      // 获取服务器文件信息
      DateTime? remoteTime;
      try {
        final remoteFileInfo = await webdavClient.getFileInfo(syncService.remoteDatabasePath);
        remoteTime = remoteFileInfo?.lastModified;
      } catch (e) {
        print('[AutoSyncService] 获取服务器文件信息失败: $e');
        // 服务器无文件或网络错误，如果本地有文件可以考虑上传
        if (localTime != null) {
          return SyncCheckResult.upload('服务器无数据，建议上传本地数据');
        }
        return SyncCheckResult.noSync('服务器连接失败，使用本地数据');
      }

      // 分析同步需求
      final result = await _analyzeSyncNeed(localTime, remoteTime, syncService);
      
      final duration = DateTime.now().difference(startTime);
      print('[AutoSyncService] 启动时同步检查完成，耗时: ${duration.inMilliseconds}ms，结果: ${result.message}');
      
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[AutoSyncService] 启动时同步检查失败，耗时: ${duration.inMilliseconds}ms，错误: $e');
      
      return SyncCheckResult.error('同步检查失败: $e');
    }
  }

  /// 分析同步需求
  static Future<SyncCheckResult> _analyzeSyncNeed(
    DateTime? localTime,
    DateTime? remoteTime,
    DatabaseSyncService syncService,
  ) async {
    // 无文件情况
    if (localTime == null && remoteTime == null) {
      return SyncCheckResult.noSync('本地和服务器都无数据文件');
    }

    // 仅本地有文件
    if (localTime != null && remoteTime == null) {
      return SyncCheckResult.upload('本地有数据，服务器无数据');
    }

    // 仅服务器有文件
    if (localTime == null && remoteTime != null) {
      return SyncCheckResult.download('服务器有数据，本地无数据');
    }

    // 两边都有文件，比较时间
    if (localTime != null && remoteTime != null) {
      final comparison = FileTimeUtils.compareTime(localTime, remoteTime);
      
      if (comparison > 0) {
        // 本地更新，检查是否有冲突
        final dbFile = await syncService.getDatabaseFile();
        final localHash = await syncService.calculateFileHash(dbFile);
        final remoteFileInfo = await syncService.webdavClient.getFileInfo(syncService.remoteDatabasePath);
        
        if (remoteFileInfo != null) {
          final conflict = await syncService.detectConflict(localHash, remoteFileInfo);
          if (conflict != null) {
            return SyncCheckResult.conflict(conflict);
          }
        }
        
        return SyncCheckResult.upload('本地数据较新');
      } else if (comparison < 0) {
        // 服务器更新，检查是否有冲突
        final dbFile = await syncService.getDatabaseFile();
        final localHash = await syncService.calculateFileHash(dbFile);
        final remoteFileInfo = await syncService.webdavClient.getFileInfo(syncService.remoteDatabasePath);
        
        if (remoteFileInfo != null) {
          final conflict = await syncService.detectConflict(localHash, remoteFileInfo);
          if (conflict != null) {
            return SyncCheckResult.conflict(conflict);
          }
        }
        
        return SyncCheckResult.download('服务器数据较新');
      } else {
        // 时间相同
        return SyncCheckResult.noSync('数据已同步');
      }
    }

    return SyncCheckResult.noSync('无需同步');
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
      print('[AutoSyncService] 开始执行启动时同步 - ${startTime.toIso8601String()}');
      
      final config = await WebDAVConfig.load();
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);

      bool success = false;
      
      switch (checkResult.direction) {
        case SyncDirection.download:
          onProgress?.call('正在从服务器下载最新数据...');
          final result = await syncService.downloadDatabase(
            forceOverwrite: false,
            onProgress: onProgress,
          ).timeout(Duration(seconds: _syncTimeoutSeconds));
          success = result.success;
          break;
          
        case SyncDirection.upload:
          onProgress?.call('正在上传本地数据到服务器...');
          final result = await syncService.uploadDatabase(
            forceOverwrite: false,
          ).timeout(Duration(seconds: _syncTimeoutSeconds));
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
      print('[AutoSyncService] 启动时同步完成，耗时: ${duration.inMilliseconds}ms，成功: $success');
      
      return success;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('[AutoSyncService] 启动时同步失败，耗时: ${duration.inMilliseconds}ms，错误: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// 场景B：开始监听数据库变化（运行时自动上传）
  static void startDatabaseWatcher(WidgetRef ref) {
    if (_dbWatcher != null) {
      return; // 已经在监听
    }

    print('[AutoSyncService] 开始监听数据库文件变化');
    
    // 开始网络状态监控
    NetworkService.initialize();
    
    // 这里先用定时检查的方式，后续可以改为文件系统监听
    _dbWatcher = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkDatabaseChanges(ref);
    });
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
        print('[AutoSyncService] 网络离线，跳过数据库变化检查');
        return;
      }

      final syncService = DatabaseSyncService(webdavClient: config.createClient());
      final databasePath = await syncService.getDatabaseFilePath();
      final currentTime = await FileTimeUtils.getLocalDatabaseTime(databasePath);
      
      if (currentTime != null && _lastSyncCheck != null) {
        if (currentTime.isAfter(_lastSyncCheck!)) {
          print('[AutoSyncService] 检测到数据库变化，准备上传');
          scheduleUpload(ref);
        }
      }
      
      _lastSyncCheck = currentTime;
    } catch (e) {
      print('[AutoSyncService] 检查数据库变化失败: $e');
    }
  }

  /// 防抖上传
  static void scheduleUpload(WidgetRef ref) {
    // 取消之前的定时器
    _uploadTimer?.cancel();
    
    print('[AutoSyncService] 安排防抖上传，延迟 $_debounceDelaySeconds 秒');
    
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
      print('[AutoSyncService] 网络离线，跳过后台上传');
      return;
    }

    _isSyncing = true;
    
    try {
      print('[AutoSyncService] 开始执行后台上传');
      
      final config = await WebDAVConfig.load();
      final webdavClient = config.createClient();
      final syncService = DatabaseSyncService(webdavClient: webdavClient);
      
      final result = await syncService.uploadDatabase(forceOverwrite: false);
      
      if (result.conflict != null) {
        print('[AutoSyncService] 后台上传检测到冲突，等待应用程序显示对话框');
        // 运行时冲突需要应用程序主动处理，这里只记录冲突信息
        // 实际的冲突对话框将由应用程序的其他部分触发显示
      } else if (result.success) {
        print('[AutoSyncService] 后台上传成功');
      } else {
        print('[AutoSyncService] 后台上传失败: ${result.message}');
      }
    } catch (e) {
      print('[AutoSyncService] 后台上传异常: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 停止监听
  static void stopWatcher() {
    print('[AutoSyncService] 停止数据库文件监听');
    
    _dbWatcher?.cancel();
    _dbWatcher = null;
    
    _uploadTimer?.cancel();
    _uploadTimer = null;
    
    // 停止网络状态监控
    NetworkService.dispose();
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
          final result = await syncService.downloadDatabase(forceOverwrite: true);
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

      print('[AutoSyncService] 强制同步完成，方向: $direction，成功: $success');
      return success;
    } catch (e) {
      print('[AutoSyncService] 强制同步失败: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}