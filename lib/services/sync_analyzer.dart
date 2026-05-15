import 'package:flowm/shared/logging/app_logger.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../models/sync_record.dart';
import '../utils/etag_utils.dart';
import '../services/webdav_client.dart';
import '../services/database_sync_service.dart';

/// 同步决策枚举
enum SyncDecision { noSync, upload, download, conflict }

/// 远程同步信息
class RemoteSyncInfo {
  final SyncAnchor anchor;
  final DateTime lastModified;
  final int size;

  RemoteSyncInfo(
      {required this.anchor, required this.lastModified, required this.size});

  /// 从 WebDAV 文件信息创建，优先使用 ETag
  factory RemoteSyncInfo.fromWebDAVFileInfo(WebDAVFileInfo info) {
    final etag = ETagUtils.normalizeEtag(info.etag);
    final anchor = ETagUtils.isValidEtag(etag)
        ? SyncAnchor.fromEtag(etag)
        : SyncAnchor.fromHash(''); // 空 Hash，需要后续下载文件计算

    return RemoteSyncInfo(
      anchor: anchor,
      lastModified: info.lastModified,
      size: info.size,
    );
  }

  /// 更新锚点值（用于 Hash 降级处理）
  RemoteSyncInfo withAnchor(SyncAnchor newAnchor) {
    return RemoteSyncInfo(
      anchor: newAnchor,
      lastModified: lastModified,
      size: size,
    );
  }

  @override
  String toString() {
    return 'RemoteSyncInfo(anchor: $anchor, modified: $lastModified, size: $size)';
  }
}

/// 同步分析器
class SyncAnalyzer {
  /// 分析同步需求
  static Future<SyncDecision> analyzeSyncNeed({
    required String? currentLocalHash,
    required RemoteSyncInfo? currentRemoteInfo,
    required SyncRecord lastSyncRecord,
    DatabaseSyncService? syncService, // 用于 Hash 降级处理
  }) async {
    AppLogger.debug('[SyncAnalyzer] 开始分析同步需求');
    AppLogger.debug('[SyncAnalyzer] 本地哈希: $currentLocalHash');
    AppLogger.debug('[SyncAnalyzer] 远程信息: $currentRemoteInfo');
    AppLogger.debug('[SyncAnalyzer] 上次同步记录: $lastSyncRecord');

    // 1. 获取当前状态的锚点
    final localAnchor =
        currentLocalHash != null ? SyncAnchor.fromHash(currentLocalHash) : null;

    SyncAnchor? remoteAnchor = currentRemoteInfo?.anchor;

    // 2. 如果远程锚点是空的 Hash（需要下载文件计算）
    if (remoteAnchor?.type == SyncAnchorType.hash &&
        remoteAnchor!.value.isEmpty &&
        syncService != null) {
      AppLogger.debug('[SyncAnalyzer] 远程 ETag 不可用，降级到 Hash 计算');
      try {
        final remoteData = await syncService.webdavClient
            .downloadFile(syncService.remoteDatabasePath);
        final remoteHash =
            await syncService.calculateFileHashFromBytes(remoteData);
        remoteAnchor = SyncAnchor.fromHash(remoteHash);
        AppLogger.debug('[SyncAnalyzer] 计算得到远程哈希: $remoteHash');
      } catch (e) {
        AppLogger.debug('[SyncAnalyzer] 下载远程文件计算哈希失败: $e');
        // 无法获取远程哈希，按照网络错误处理
        remoteAnchor = null;
      }
    }

    // 3. 获取上次同步记录的锚点
    final lastLocalAnchor = lastSyncRecord.lastLocalHash != null
        ? SyncAnchor.fromHash(lastSyncRecord.lastLocalHash!)
        : null;

    final lastRemoteAnchor = _getLastRemoteAnchor(lastSyncRecord);

    // 4. 判断变化
    final localChanged = _hasAnchorChanged(localAnchor, lastLocalAnchor);
    final remoteChanged = _hasAnchorChanged(remoteAnchor, lastRemoteAnchor);

    AppLogger.debug('[SyncAnalyzer] 本地是否变化: $localChanged');
    AppLogger.debug('[SyncAnalyzer] 远程是否变化: $remoteChanged');

    // 5. 特殊情况处理
    // 5.1 如果没有有效的同步记录，按照首次同步处理
    if (!lastSyncRecord.hasValidRecord) {
      AppLogger.debug('[SyncAnalyzer] 无有效同步记录，按首次同步处理');
      return _analyzeFirstTimeSync(localAnchor, remoteAnchor);
    }

    // 5.2 网络连接问题（无法获取远程信息）
    if (currentRemoteInfo == null || remoteAnchor == null) {
      if (localAnchor != null) {
        AppLogger.debug('[SyncAnalyzer] 网络连接问题，建议上传本地数据');
        return SyncDecision.upload;
      } else {
        AppLogger.debug('[SyncAnalyzer] 网络连接问题，无本地数据，无需同步');
        return SyncDecision.noSync;
      }
    }

    // 6. 决定同步方向
    if (!localChanged && !remoteChanged) {
      AppLogger.debug('[SyncAnalyzer] 双方都没变化，无需同步');
      return SyncDecision.noSync;
    } else if (localChanged && !remoteChanged) {
      AppLogger.debug('[SyncAnalyzer] 仅本地变化，需要上传');
      return SyncDecision.upload;
    } else if (!localChanged && remoteChanged) {
      AppLogger.debug('[SyncAnalyzer] 仅远程变化，需要下载');
      return SyncDecision.download;
    } else {
      AppLogger.debug('[SyncAnalyzer] 双方都有变化，存在冲突');
      return SyncDecision.conflict;
    }
  }

  /// 获取上次同步记录的远程锚点
  static SyncAnchor? _getLastRemoteAnchor(SyncRecord record) {
    if (record.lastRemoteEtag != null &&
        ETagUtils.isValidEtag(record.lastRemoteEtag)) {
      return SyncAnchor.fromEtag(record.lastRemoteEtag!);
    } else if (record.lastRemoteHash != null) {
      return SyncAnchor.fromHash(record.lastRemoteHash!);
    }
    return null;
  }

  /// 判断锚点是否发生变化
  static bool _hasAnchorChanged(SyncAnchor? current, SyncAnchor? last) {
    // 如果上次没有记录，认为有变化
    if (last == null) return current != null;

    // 如果当前没有数据，认为有变化
    if (current == null) return true;

    // 比较锚点值
    return !current.equals(last);
  }

  /// 分析首次同步情况
  static SyncDecision _analyzeFirstTimeSync(
      SyncAnchor? local, SyncAnchor? remote) {
    if (local == null && remote == null) {
      // 双方都无数据
      return SyncDecision.noSync;
    } else if (local != null && remote == null) {
      // 仅本地有数据
      return SyncDecision.upload;
    } else if (local == null && remote != null) {
      // 仅远程有数据
      return SyncDecision.download;
    } else {
      // 双方都有数据，需要用户选择
      return SyncDecision.conflict;
    }
  }
}

/// 扩展 DatabaseSyncService 支持从字节数组计算哈希
extension DatabaseSyncServiceExtension on DatabaseSyncService {
  /// 从字节数组计算文件哈希
  Future<String> calculateFileHashFromBytes(List<int> bytes) async {
    final digest = crypto.md5.convert(bytes);
    return digest.toString();
  }
}
