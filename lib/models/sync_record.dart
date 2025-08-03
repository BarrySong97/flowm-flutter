import '../utils/etag_utils.dart';

/// 同步记录数据类
/// 存储最后一次同步的本地和远程文件信息
class SyncRecord {
  final String? lastLocalHash;      // 最后同步时的本地文件 MD5
  final String? lastRemoteEtag;     // 最后同步时的远程 ETag（优先）
  final String? lastRemoteHash;     // 备用：最后同步时的远程文件 MD5
  final DateTime? lastSyncTime;     // 同步时间（仅用于显示）
  
  const SyncRecord({
    this.lastLocalHash,
    this.lastRemoteEtag,
    this.lastRemoteHash,
    this.lastSyncTime,
  });
  
  /// 用于判断是否有有效的同步记录
  bool get hasValidRecord => 
    lastLocalHash != null && 
    (lastRemoteEtag != null || lastRemoteHash != null);
  
  /// 获取远程锚点值（优先 ETag，其次 Hash）
  String? get remoteAnchor {
    if (lastRemoteEtag != null && ETagUtils.isValidEtag(lastRemoteEtag)) {
      return ETagUtils.normalizeEtag(lastRemoteEtag);
    }
    return lastRemoteHash;
  }
  
  /// 获取远程锚点类型
  SyncAnchorType? get remoteAnchorType {
    if (lastRemoteEtag != null && ETagUtils.isValidEtag(lastRemoteEtag)) {
      return SyncAnchorType.etag;
    } else if (lastRemoteHash != null) {
      return SyncAnchorType.hash;
    }
    return null;
  }
  
  @override
  String toString() {
    return 'SyncRecord(localHash: $lastLocalHash, remoteEtag: $lastRemoteEtag, remoteHash: $lastRemoteHash, syncTime: $lastSyncTime)';
  }
}

/// 同步锚点类型
enum SyncAnchorType { etag, hash }

/// 同步锚点
class SyncAnchor {
  final SyncAnchorType type;
  final String value;
  
  const SyncAnchor({required this.type, required this.value});
  
  factory SyncAnchor.fromEtag(String etag) => 
    SyncAnchor(type: SyncAnchorType.etag, value: ETagUtils.normalizeEtag(etag));
    
  factory SyncAnchor.fromHash(String hash) => 
    SyncAnchor(type: SyncAnchorType.hash, value: hash);
  
  bool equals(SyncAnchor other) {
    if (type != other.type) return false;
    return value == other.value;
  }
  
  @override
  String toString() {
    return 'SyncAnchor(type: $type, value: $value)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncAnchor &&
        other.type == type &&
        other.value == value;
  }
  
  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}