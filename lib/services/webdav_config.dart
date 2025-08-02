import 'package:shared_preferences/shared_preferences.dart';
import 'webdav_client.dart';

class WebDAVConfig {
  static const String _urlKey = 'webdav_url';
  static const String _usernameKey = 'webdav_username';
  static const String _passwordKey = 'webdav_password';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _lastLocalHashKey = 'last_local_hash';
  static const String _lastRemoteHashKey = 'last_remote_hash';

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
    await clearSyncStatus();
  }

  // 保存同步状态
  static Future<void> saveSyncStatus({
    required String localHash,
    required String remoteHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setInt(_lastSyncTimeKey, now);
    await prefs.setString(_lastLocalHashKey, localHash);
    await prefs.setString(_lastRemoteHashKey, remoteHash);
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

  // 清除同步状态
  static Future<void> clearSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncTimeKey);
    await prefs.remove(_lastLocalHashKey);
    await prefs.remove(_lastRemoteHashKey);
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