import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_sync_service.dart';
import '../services/webdav_config.dart';
import '../services/network_service.dart';
import '../utils/file_time_utils.dart';
import '../utils/global_refresh_service.dart';
import '../services/sync_analyzer.dart';
import '../models/sync_record.dart';

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

      // 检查是否曾经同步过
      final hasEverSynced = await _hasEverSynced();

      // 如果从未同步过，进入首次配置处理流程
      if (!hasEverSynced) {
        print('[AutoSyncService] 检测到从未同步过，进入首次配置处理');
        // return await _handleFirstTimeSync(localTime, remoteTime, syncService);
      }

      // 分析同步需求
      final result = await _analyzeSyncNeed(syncService);

      final duration = DateTime.now().difference(startTime);
      print(
          '[AutoSyncService] 启动时同步检查完成，耗时: ${duration.inMilliseconds}ms，结果: ${result.message}');

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print(
          '[AutoSyncService] 启动时同步检查失败，耗时: ${duration.inMilliseconds}ms，错误: $e');

      return SyncCheckResult.error('同步检查失败: $e');
    }
  }

  /// 分析同步需求（基于 ETag/Hash）
  static Future<SyncCheckResult> _analyzeSyncNeed(
    DatabaseSyncService syncService,
  ) async {
    try {
      print('[AutoSyncService] 开始基于 ETag/Hash 的同步分析');
      
      // 1. 获取本地文件哈希
      String? currentLocalHash;
      try {
        final dbFile = await syncService.getDatabaseFile();
        if (await dbFile.exists()) {
          currentLocalHash = await syncService.calculateFileHash(dbFile);
          print('[AutoSyncService] 本地文件哈希: $currentLocalHash');
        } else {
          print('[AutoSyncService] 本地文件不存在');
        }
      } catch (e) {
        print('[AutoSyncService] 获取本地文件哈希失败: $e');
      }
      
      // 2. 获取远程文件信息
      RemoteSyncInfo? currentRemoteInfo;
      try {
        final remoteFileInfo = await syncService.webdavClient
            .getFileInfo(syncService.remoteDatabasePath);
        if (remoteFileInfo != null) {
          currentRemoteInfo = RemoteSyncInfo.fromWebDAVFileInfo(remoteFileInfo);
          print('[AutoSyncService] 远程文件信息: $currentRemoteInfo');
        } else {
          print('[AutoSyncService] 远程文件不存在');
        }
      } catch (e) {
        print('[AutoSyncService] 获取远程文件信息失败: $e');
      }
      
      // 3. 获取上次同步记录
      final lastSyncRecord = await WebDAVConfig.getSyncRecord();
      print('[AutoSyncService] 上次同步记录: $lastSyncRecord');
      
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
            currentLocalHash, 
            currentRemoteInfo, 
            syncService
          );
          return SyncCheckResult.conflict(conflict);
      }
    } catch (e) {
      print('[AutoSyncService] 同步分析过程发生错误: $e');
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
          print('[AutoSyncService] 获取远程文件哈希失败: $e');
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
      print('[AutoSyncService] 构建冲突信息失败: $e');
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
      print('[AutoSyncService] 开始执行启动时同步 - ${startTime.toIso8601String()}');

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
      print(
          '[AutoSyncService] 启动时同步完成，耗时: ${duration.inMilliseconds}ms，成功: $success');

      return success;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print(
          '[AutoSyncService] 启动时同步失败，耗时: ${duration.inMilliseconds}ms，错误: $e');
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

      final syncService =
          DatabaseSyncService(webdavClient: config.createClient());
      final databasePath = await syncService.getDatabaseFilePath();
      final currentTime =
          await FileTimeUtils.getLocalDatabaseTime(databasePath);

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
      print('[AutoSyncService] 检查同步历史失败: $e');
      // 如果检查失败，保守地认为从未同步过
      return false;
    }
  }

  /// 处理首次同步的情况
  static Future<SyncCheckResult> _handleFirstTimeSync(
    DateTime? localTime,
    DateTime? remoteTime,
    DatabaseSyncService syncService,
  ) async {
    // 情况1: 无本地无远程 - 全新安装
    if (localTime == null && remoteTime == null) {
      return SyncCheckResult.noSync('全新安装，无需同步');
    }

    // 情况2: 无本地有远程 - 跨设备安装
    if (localTime == null && remoteTime != null) {
      return SyncCheckResult.download('检测到云端数据，建议下载');
    }

    // 情况3: 有本地无远程 - 首次使用或网络问题
    if (localTime != null && remoteTime == null) {
      // 检查是否为默认数据库（通过文件创建时间判断）
      final isRecentlyCreated = await _isRecentlyCreated(syncService);
      if (isRecentlyCreated) {
        return SyncCheckResult.noSync('首次安装，无需同步');
      } else {
        return SyncCheckResult.upload('检测到本地数据，建议上传');
      }
    }

    // 情况4: 有本地有远程 - 需要用户选择或智能判断
    if (localTime != null && remoteTime != null) {
      // 检查是否为最近创建的默认数据库
      final isRecentlyCreated = await _isRecentlyCreated(syncService);
      if (isRecentlyCreated) {
        // 本地是默认数据，云端有数据，很可能是跨设备安装
        return SyncCheckResult.download('检测到云端数据，建议下载');
      } else {
        // 本地有用户数据，云端也有数据，需要用户选择
        // 构建冲突信息让用户决定
        final dbFile = await syncService.getDatabaseFile();
        final localStat = await dbFile.stat();

        return SyncCheckResult.conflict(SyncConflict(
          localModified: localTime,
          remoteModified: remoteTime,
          localSize: localStat.size,
          remoteSize: 0, // 暂时设为0，实际使用时会获取真实大小
          localHash: 'unknown',
          remoteHash: 'unknown',
        ));
      }
    }

    // 默认情况，不应该到达这里
    return SyncCheckResult.noSync('无法确定同步需求');
  }

  /// 检查数据库文件是否为最近创建的默认文件
  static Future<bool> _isRecentlyCreated(
      DatabaseSyncService syncService) async {
    try {
      final dbFile = await syncService.getDatabaseFile();
      if (!await dbFile.exists()) return true;

      final stat = await dbFile.stat();
      final fileAge = DateTime.now().difference(stat.changed);

      // 如果文件创建时间在10分钟内，认为是最近创建的默认文件
      return fileAge.inMinutes < 10;
    } catch (e) {
      print('[AutoSyncService] 检查文件创建时间失败: $e');
      // 检查失败时保守地认为不是最近创建的
      return false;
    }
  }

  /// 检查是否从未同步过（保留兼容性）
  static Future<bool> _hasNeverSynced(DatabaseSyncService syncService) async {
    return !(await _hasEverSynced());
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
