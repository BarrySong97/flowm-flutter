import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'webdav_client.dart';
import 'webdav_config.dart';

class DatabaseSyncService {
  static const String _databaseFileName = 'flowm_database.sqlite';
  static const String _backupPrefix = 'database_backup_';
  static const int _maxBackupCount = 5;

  final WebDAVClient webdavClient;

  DatabaseSyncService({required this.webdavClient});

  // 获取远程文件路径
  String get _remoteDatabasePath {
    // 使用 flowm-app 目录，这个路径在坚果云中工作正常
    return 'flowm-app/$_databaseFileName';
  }

  // 公共方法：获取远程数据库路径
  String get remoteDatabasePath => _remoteDatabasePath;

  // 获取数据库文件路径
  Future<String> getDatabaseFilePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, _databaseFileName);
  }

  // 获取数据库文件
  Future<File> getDatabaseFile() async {
    final path = await getDatabaseFilePath();
    return File(path);
  }

  // 计算文件哈希值
  Future<String> calculateFileHash(File file) async {
    if (!await file.exists()) {
      throw Exception('文件不存在: ${file.path}');
    }

    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // 创建本地备份
  Future<File> createBackup() async {
    try {
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      final dbFolder = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = '$_backupPrefix$timestamp.db';
      final backupPath = p.join(dbFolder.path, backupFileName);

      final backupFile = await dbFile.copy(backupPath);

      // 清理旧备份
      await _cleanupOldBackups();

      return backupFile;
    } catch (e) {
      throw Exception('创建备份失败: $e');
    }
  }

  // 清理旧备份文件
  Future<void> _cleanupOldBackups() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final files = await dbFolder.list().toList();

      final backupFiles = files
          .whereType<File>()
          .where((file) => p.basename(file.path).startsWith(_backupPrefix))
          .toList();

      // 按修改时间排序，保留最新的N个备份
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (backupFiles.length > _maxBackupCount) {
        final filesToDelete = backupFiles.sublist(_maxBackupCount);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      // 清理失败不影响主要功能
    }
  }

  // 上传数据库到服务器
  Future<SyncResult> uploadDatabase({bool forceOverwrite = false}) async {
    final startTime = DateTime.now();
    print('[DatabaseSyncService] 开始上传数据库 - ${startTime.toIso8601String()}');
    
    try {
      // 检查数据库文件是否存在
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      // 如果强制覆盖，跳过冲突检测直接上传
      if (forceOverwrite) {
        print('[DatabaseSyncService] 强制上传模式，跳过冲突检测');
        
        final uploadStartTime = DateTime.now();
        final success = await webdavClient.uploadFile(_remoteDatabasePath, dbFile);
        final uploadEndTime = DateTime.now();
        final uploadDuration = uploadEndTime.difference(uploadStartTime);
        print('[DatabaseSyncService] 强制上传完成，耗时: ${uploadDuration.inMilliseconds}ms');

        if (success) {
          // 快速更新同步记录
          final localHash = await calculateFileHash(dbFile);
          await _updateSyncRecord(localHash, localHash);

          final totalDuration = DateTime.now().difference(startTime);
          print('[DatabaseSyncService] 强制上传流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

          return SyncResult(
            success: true,
            message: '强制上传成功',
            timestamp: DateTime.now(),
          );
        } else {
          throw Exception('上传失败');
        }
      }

      // 正常上传流程
      // 计算本地文件哈希
      final localHash = await calculateFileHash(dbFile);

      // 检查远程文件是否存在
      final remoteFileInfo = await webdavClient.getFileInfo(_remoteDatabasePath);

      // 冲突检测
      if (remoteFileInfo != null) {
        final conflict = await detectConflict(localHash, remoteFileInfo);
        if (conflict != null) {
          return SyncResult(
            success: false,
            message: '检测到冲突',
            conflict: conflict,
          );
        }
      }

      // 执行上传
      final uploadStartTime = DateTime.now();
      final success = await webdavClient.uploadFile(_remoteDatabasePath, dbFile);
      final uploadEndTime = DateTime.now();
      final uploadDuration = uploadEndTime.difference(uploadStartTime);
      print('[DatabaseSyncService] 上传完成，耗时: ${uploadDuration.inMilliseconds}ms');

      if (success) {
        // 更新同步记录
        await _updateSyncRecord(localHash, localHash);

        final totalDuration = DateTime.now().difference(startTime);
        print('[DatabaseSyncService] 上传流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

        return SyncResult(
          success: true,
          message: '上传成功',
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('上传失败');
      }
    } catch (e) {
      final errorDuration = DateTime.now().difference(startTime);
      print('[DatabaseSyncService] 上传失败，总耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      
      return SyncResult(
        success: false,
        message: '上传失败: $e',
      );
    }
  }

  // 从服务器下载数据库
  Future<SyncResult> downloadDatabase({
    bool forceOverwrite = false,
    Function(String)? onProgress,
  }) async {
    final startTime = DateTime.now();
    print('[DatabaseSyncService] 开始下载数据库 - ${startTime.toIso8601String()}');
    
    try {
      // 检查远程文件是否存在
      onProgress?.call('正在检查远程文件...');
      final checkRemoteStartTime = DateTime.now();
      final remoteFileInfo =
          await webdavClient.getFileInfo(_remoteDatabasePath);
      final checkRemoteEndTime = DateTime.now();
      final checkRemoteDuration = checkRemoteEndTime.difference(checkRemoteStartTime);
      print('[DatabaseSyncService] 检查远程文件完成，耗时: ${checkRemoteDuration.inMilliseconds}ms');
      
      if (remoteFileInfo == null) {
        throw Exception('服务器上不存在数据库文件');
      }

      final dbFile = await getDatabaseFile();
      
      // 如果强制覆盖，跳过所有检测直接下载
      if (forceOverwrite) {
        onProgress?.call('正在强制下载...');
        
        // 只在文件存在时创建备份，且并行进行
        Future<void>? backupFuture;
        if (await dbFile.exists()) {
          backupFuture = createBackup();
        }
        
        // 并行下载文件
        final downloadStartTime = DateTime.now();
        final remoteDataFuture = webdavClient.downloadFile(_remoteDatabasePath);
        
        // 等待备份完成（如果需要）
        if (backupFuture != null) {
          await backupFuture;
        }
        
        // 等待下载完成
        final remoteData = await remoteDataFuture;
        final downloadEndTime = DateTime.now();
        final downloadDuration = downloadEndTime.difference(downloadStartTime);
        print('[DatabaseSyncService] 下载远程文件完成，文件大小: ${remoteData.length} bytes，耗时: ${downloadDuration.inMilliseconds}ms');

        // 直接写入，跳过完整性验证（因为是强制覆盖）
        onProgress?.call('正在写入文件...');
        final writeStartTime = DateTime.now();
        await dbFile.writeAsBytes(remoteData);
        final writeEndTime = DateTime.now();
        final writeDuration = writeEndTime.difference(writeStartTime);
        print('[DatabaseSyncService] 写入本地文件完成，耗时: ${writeDuration.inMilliseconds}ms');

        // 快速更新同步记录（使用远程文件信息，避免重新计算哈希）
        onProgress?.call('正在更新记录...');
        final remoteHash = md5.convert(remoteData).toString();
        await _updateSyncRecord(remoteHash, remoteHash);

        final totalDuration = DateTime.now().difference(startTime);
        print('[DatabaseSyncService] 强制下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

        return SyncResult(
          success: true,
          message: '强制下载成功',
          timestamp: DateTime.now(),
        );
      }

      // 正常下载流程（非强制覆盖）
      String? localHash;
      if (await dbFile.exists()) {
        onProgress?.call('正在检查本地文件...');
        final hashStartTime = DateTime.now();
        localHash = await calculateFileHash(dbFile);
        final hashEndTime = DateTime.now();
        final hashDuration = hashEndTime.difference(hashStartTime);
        print('[DatabaseSyncService] 计算本地文件哈希完成，耗时: ${hashDuration.inMilliseconds}ms');
      }

      // 冲突检测
      if (localHash != null) {
        onProgress?.call('正在检测冲突...');
        final conflictStartTime = DateTime.now();
        final conflict = await detectConflict(localHash, remoteFileInfo);
        final conflictEndTime = DateTime.now();
        final conflictDuration = conflictEndTime.difference(conflictStartTime);
        print('[DatabaseSyncService] 冲突检测完成，耗时: ${conflictDuration.inMilliseconds}ms');
        
        if (conflict != null) {
          return SyncResult(
            success: false,
            message: '检测到冲突',
            conflict: conflict,
          );
        }
      }

      // 并行执行备份和下载
      onProgress?.call('正在下载文件...');
      
      Future<void>? backupFuture;
      if (await dbFile.exists()) {
        backupFuture = createBackup();
      }
      
      final downloadStartTime = DateTime.now();
      final remoteDataFuture = webdavClient.downloadFile(_remoteDatabasePath);
      
      // 等待备份完成
      if (backupFuture != null) {
        await backupFuture;
      }
      
      // 等待下载完成
      final remoteData = await remoteDataFuture;
      final downloadEndTime = DateTime.now();
      final downloadDuration = downloadEndTime.difference(downloadStartTime);
      print('[DatabaseSyncService] 下载和备份完成，耗时: ${downloadDuration.inMilliseconds}ms');

      // 快速写入（减少验证步骤）
      onProgress?.call('正在保存文件...');
      final writeStartTime = DateTime.now();
      await dbFile.writeAsBytes(remoteData);
      
      // 只计算一次哈希用于同步记录
      final remoteHash = md5.convert(remoteData).toString();
      await _updateSyncRecord(remoteHash, remoteHash);
      
      final writeEndTime = DateTime.now();
      final writeDuration = writeEndTime.difference(writeStartTime);
      print('[DatabaseSyncService] 写入和记录更新完成，耗时: ${writeDuration.inMilliseconds}ms');

      final totalDuration = DateTime.now().difference(startTime);
      print('[DatabaseSyncService] 数据库下载流程完成，总耗时: ${totalDuration.inMilliseconds}ms');

      return SyncResult(
        success: true,
        message: '下载成功',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      final errorDuration = DateTime.now().difference(startTime);
      print('[DatabaseSyncService] 下载失败，总耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      
      return SyncResult(
        success: false,
        message: '下载失败: $e',
      );
    }
  }

  // 检测同步冲突
  Future<SyncConflict?> detectConflict(
      String localHash, WebDAVFileInfo remoteFileInfo) async {
    try {
      final lastLocalHash = await WebDAVConfig.getLastLocalHash();
      final lastRemoteHash = await WebDAVConfig.getLastRemoteHash();

      // 快速检查：如果没有上次同步记录，不算冲突
      if (lastLocalHash == null || lastRemoteHash == null) {
        return null;
      }

      // 快速检查：如果本地文件没有变化，不算冲突
      if (localHash == lastLocalHash) {
        return null;
      }

      // 只有在确实需要时才下载远程文件计算哈希
      // 先基于文件大小和修改时间做快速判断
      final dbFile = await getDatabaseFile();
      final localStat = await dbFile.stat();
      
      // 如果文件大小和上次记录的相同，且本地有变化，可能有冲突
      // 但避免立即下载，先检查时间戳
      final timeDiff = remoteFileInfo.lastModified.difference(localStat.modified).abs();
      
      // 如果时间差小于5秒，可能是同一次操作，不算冲突
      if (timeDiff.inSeconds < 5) {
        return null;
      }

      // 只有在真正需要时才下载远程文件计算哈希
      print('[DatabaseSyncService] 需要下载远程文件进行冲突检测');
      final remoteData = await webdavClient.downloadFile(_remoteDatabasePath);
      final remoteHash = md5.convert(remoteData).toString();

      // 检查远程是否有变化
      final remoteChanged = remoteHash != lastRemoteHash;
      
      // 只有本地和远程都有变化，且哈希不同，才是真正的冲突
      if (remoteChanged && localHash != remoteHash) {
        return SyncConflict(
          localModified: localStat.modified,
          remoteModified: remoteFileInfo.lastModified,
          localSize: localStat.size,
          remoteSize: remoteFileInfo.size,
          localHash: localHash,
          remoteHash: remoteHash,
        );
      }

      return null;
    } catch (e) {
      print('[DatabaseSyncService] 冲突检测出错，为安全起见报告冲突: $e');
      // 如果检测冲突失败，谨慎起见返回冲突
      final dbFile = await getDatabaseFile();
      final localStat = await dbFile.stat();

      return SyncConflict(
        localModified: localStat.modified,
        remoteModified: remoteFileInfo.lastModified,
        localSize: localStat.size,
        remoteSize: remoteFileInfo.size,
        localHash: localHash,
        remoteHash: 'unknown',
      );
    }
  }

  // 更新同步记录
  Future<void> _updateSyncRecord(String localHash, String remoteHash) async {
    await WebDAVConfig.saveSyncStatus(
      localHash: localHash,
      remoteHash: remoteHash,
    );
  }

  // 获取最后同步时间
  Future<DateTime?> getLastSyncTime() async {
    return await WebDAVConfig.getLastSyncTime();
  }

  // 获取同步状态
  Future<SyncStatus> getSyncStatus() async {
    try {
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        return SyncStatus(
          isInSync: false,
          message: '本地数据库不存在',
        );
      }

      final remoteFileInfo =
          await webdavClient.getFileInfo(_remoteDatabasePath);

      if (remoteFileInfo == null) {
        return SyncStatus(
          isInSync: false,
          message: '服务器上不存在数据库文件',
        );
      }

      // 简单检查：如果能够连接到服务器且文件存在，认为可以同步
      final lastSyncTime = await getLastSyncTime();

      return SyncStatus(
        isInSync: true,
        message: '可以同步',
        lastSyncTime: lastSyncTime,
        localSize: (await dbFile.stat()).size,
        remoteSize: remoteFileInfo.size,
      );
    } catch (e) {
      return SyncStatus(
        isInSync: false,
        message: '检查同步状态失败: $e',
      );
    }
  }
}

// 同步结果类
class SyncResult {
  final bool success;
  final String message;
  final DateTime? timestamp;
  final SyncConflict? conflict;

  SyncResult({
    required this.success,
    required this.message,
    this.timestamp,
    this.conflict,
  });
}

// 同步冲突类
class SyncConflict {
  final DateTime localModified;
  final DateTime remoteModified;
  final int localSize;
  final int remoteSize;
  final String localHash;
  final String remoteHash;

  SyncConflict({
    required this.localModified,
    required this.remoteModified,
    required this.localSize,
    required this.remoteSize,
    required this.localHash,
    required this.remoteHash,
  });
}

// 同步状态类
class SyncStatus {
  final bool isInSync;
  final String message;
  final DateTime? lastSyncTime;
  final int? localSize;
  final int? remoteSize;

  SyncStatus({
    required this.isInSync,
    required this.message,
    this.lastSyncTime,
    this.localSize,
    this.remoteSize,
  });
}
