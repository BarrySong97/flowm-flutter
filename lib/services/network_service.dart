import 'package:flowm/shared/logging/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 网络状态
enum NetworkStatus {
  online, // 在线
  offline, // 离线
  unknown, // 未知
}

/// 网络状态监听服务
class NetworkService {
  static NetworkStatus _currentStatus = NetworkStatus.unknown;
  static final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();
  static Timer? _checkTimer;
  static bool _isInitialized = false;

  /// 当前网络状态
  static NetworkStatus get currentStatus => _currentStatus;

  /// 网络状态变化流
  static Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// 是否在线
  static bool get isOnline => _currentStatus == NetworkStatus.online;

  /// 是否离线
  static bool get isOffline => _currentStatus == NetworkStatus.offline;

  /// 初始化网络监听
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    // 立即检查一次网络状态
    await _checkNetworkStatus();

    // 开始定期检查网络状态
    _startPeriodicCheck();

    if (kDebugMode) {
      AppLogger.debug('[NetworkService] 网络监听已初始化，当前状态: $_currentStatus');
    }
  }

  /// 开始定期检查网络状态
  static void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNetworkStatus();
    });
  }

  /// 检查网络状态
  static Future<void> _checkNetworkStatus() async {
    NetworkStatus newStatus;

    try {
      // 在Web环境中使用不同的检查方式
      if (kIsWeb) {
        newStatus = await _checkWebNetworkStatus();
      } else {
        newStatus = await _checkMobileNetworkStatus();
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('[NetworkService] 网络状态检查失败: $e');
      }
      newStatus = NetworkStatus.unknown;
    }

    if (newStatus != _currentStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);

      if (kDebugMode) {
        AppLogger.debug(
            '[NetworkService] 网络状态变化: $oldStatus -> $_currentStatus');
      }
    }
  }

  /// 检查移动端网络状态
  static Future<NetworkStatus> _checkMobileNetworkStatus() async {
    try {
      // 尝试连接到可靠的服务器
      final addresses = await InternetAddress.lookup(
        'dns.google',
        type: InternetAddressType.any,
      ).timeout(const Duration(seconds: 5));

      if (addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty) {
        return NetworkStatus.online;
      } else {
        return NetworkStatus.offline;
      }
    } catch (e) {
      return NetworkStatus.offline;
    }
  }

  /// 检查Web端网络状态
  static Future<NetworkStatus> _checkWebNetworkStatus() async {
    try {
      // Web环境中使用HTTP请求检查网络
      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse('https://dns.google'))
          .timeout(const Duration(seconds: 5));
      final response =
          await request.close().timeout(const Duration(seconds: 5));

      client.close();

      if (response.statusCode == 200) {
        return NetworkStatus.online;
      } else {
        return NetworkStatus.offline;
      }
    } catch (e) {
      return NetworkStatus.offline;
    }
  }

  /// 手动检查网络状态
  static Future<NetworkStatus> checkStatus() async {
    await _checkNetworkStatus();
    return _currentStatus;
  }

  /// 等待网络连接
  static Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOnline) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;
    Timer? timeoutTimer;

    subscription = statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        timeoutTimer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // 立即检查一次
    await checkStatus();
    if (isOnline) {
      timeoutTimer.cancel();
      subscription.cancel();
      return true;
    }

    return completer.future;
  }

  /// 检查特定主机是否可达
  static Future<bool> canReachHost(String host, {int port = 80}) async {
    try {
      final socket =
          await Socket.connect(host, port).timeout(const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 停止网络监听
  static void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isInitialized = false;

    if (kDebugMode) {
      AppLogger.debug('[NetworkService] 网络监听已停止');
    }
  }

  /// 获取网络状态描述
  static String getStatusDescription(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return '网络连接正常';
      case NetworkStatus.offline:
        return '网络连接断开';
      case NetworkStatus.unknown:
        return '网络状态未知';
    }
  }

  /// 检查WebDAV服务器是否可达
  static Future<bool> canReachWebDAVServer(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final port =
          uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);

      return await canReachHost(host, port: port);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('[NetworkService] WebDAV服务器连接检查失败: $e');
      }
      return false;
    }
  }
}
