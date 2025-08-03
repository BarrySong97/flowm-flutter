import 'package:shared_preferences/shared_preferences.dart';
import 'webdav_client.dart';
import '../utils/etag_utils.dart';
import '../models/sync_record.dart';

class WebDAVConfig {
  static const String _urlKey = 'webdav_url';
  static const String _usernameKey = 'webdav_username';
  static const String _passwordKey = 'webdav_password';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _lastLocalHashKey = 'last_local_hash';
  static const String _lastRemoteHashKey = 'last_remote_hash';
  static const String _lastRemoteEtagKey = 'last_remote_etag';
  static const String _firstConfigTimeKey = 'first_config_time';

  final String url;
  final String username;
  final String password;

  WebDAVConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  // 检查配置是否完整
  bool get isValid => url.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  // 创建 WebDAV 客户端
  WebDAVClient createClient() {
    if (!isValid) {
      throw Exception('WebDAV配置不完整');
    }
    return WebDAVClient(
      baseUrl: url,
      username: username,
      password: password,
    );
  }

  // 保存配置到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查是否为首次配置
    final firstConfigTime = prefs.getInt(_firstConfigTimeKey);
    if (firstConfigTime == null) {
      // 记录首次配置时间
      await prefs.setInt(_firstConfigTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
    
    await prefs.setString(_urlKey, url);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  // 从 SharedPreferences 加载配置
  static Future<WebDAVConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WebDAVConfig(
      url: prefs.getString(_urlKey) ?? '',
      username: prefs.getString(_usernameKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  // 清除配置
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_firstConfigTimeKey);
    await clearSyncStatus();
  }

  // 保存同步状态（支持 ETag 优先）
  static Future<void> saveSyncStatus({
    required String localHash,
    String? remoteEtag,
    String? remoteHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setInt(_lastSyncTimeKey, now);
    await prefs.setString(_lastLocalHashKey, localHash);
    
    // 优先保存 ETag，如果有效的话
    if (remoteEtag != null && ETagUtils.isValidEtag(remoteEtag)) {
      await prefs.setString(_lastRemoteEtagKey, ETagUtils.normalizeEtag(remoteEtag));
      await prefs.remove(_lastRemoteHashKey); // 清除备用 Hash
    } else if (remoteHash != null) {
      await prefs.setString(_lastRemoteHashKey, remoteHash);
      await prefs.remove(_lastRemoteEtagKey); // 清除 ETag
    }
  }

  // 获取最后同步时间
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // 获取最后本地文件哈希
  static Future<String?> getLastLocalHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLocalHashKey);
  }

  // 获取最后远程文件哈希
  static Future<String?> getLastRemoteHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRemoteHashKey);
  }

  // 获取最后远程文件 ETag
  static Future<String?> getLastRemoteEtag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRemoteEtagKey);
  }

  // 获取完整的同步记录
  static Future<SyncRecord> getSyncRecord() async {
    final prefs = await SharedPreferences.getInstance();
    
    final syncTime = prefs.getInt(_lastSyncTimeKey);
    
    return SyncRecord(
      lastLocalHash: prefs.getString(_lastLocalHashKey),
      lastRemoteEtag: prefs.getString(_lastRemoteEtagKey),
      lastRemoteHash: prefs.getString(_lastRemoteHashKey),
      lastSyncTime: syncTime != null ? DateTime.fromMillisecondsSinceEpoch(syncTime) : null,
    );
  }

  // 获取首次配置时间
  static Future<DateTime?> getFirstConfigTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_firstConfigTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // 设置首次配置时间（用于测试或特殊场景）
  static Future<void> setFirstConfigTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_firstConfigTimeKey, time.millisecondsSinceEpoch);
  }

  // 检查是否为首次配置
  static Future<bool> isFirstTimeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_firstConfigTimeKey) == null;
  }

  // 清除同步状态
  static Future<void> clearSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncTimeKey);
    await prefs.remove(_lastLocalHashKey);
    await prefs.remove(_lastRemoteHashKey);
    await prefs.remove(_lastRemoteEtagKey);
  }

  // 复制并修改配置
  WebDAVConfig copyWith({
    String? url,
    String? username,
    String? password,
  }) {
    return WebDAVConfig(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    // 不输出密码信息
    return 'WebDAVConfig(url: $url, username: $username, password: [HIDDEN])';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebDAVConfig &&
        other.url == url &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => url.hashCode ^ username.hashCode ^ password.hashCode;
}