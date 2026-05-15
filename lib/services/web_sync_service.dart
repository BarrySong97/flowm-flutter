import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WebSyncService {
  static HttpServer? _server;
  static String? _serverUrl;
  static final NetworkInfo _networkInfo = NetworkInfo();

  // 获取局域网IP地址
  static Future<String?> getLocalIpAddress() async {
    try {
      if (kIsWeb) {
        return null; // Web环境无法获取本地IP
      }

      // 获取WiFi IP地址
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }

      // 如果获取不到WiFi IP，尝试其他方法
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
                  !addr.isLoopback &&
                  addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('获取IP地址失败: $e');
      return null;
    }
  }

  // 启动HTTP服务器
  static Future<String?> startServer({int port = 8080}) async {
    try {
      if (_server != null) {
        await stopServer();
      }

      final ip = await getLocalIpAddress();
      if (ip == null) {
        throw Exception('无法获取本地IP地址');
      }

      final router = Router()
        ..get('/api/getSqlFile', _handleGetSqlFile)
        ..get('/api/status', _handleStatus)
        ..get('/api/dbInfo', _handleDbInfo)
        ..get('/', _handleIndex);

      // 添加CORS middleware
      final handler =
          Pipeline().addMiddleware(_corsMiddleware).addHandler(router.call);

      _server = await serve(
        handler,
        ip,
        port,
      );

      _serverUrl = 'http://$ip:$port';
      debugPrint('Web同步服务已启动: $_serverUrl');
      return _serverUrl;
    } catch (e) {
      debugPrint('启动服务器失败: $e');
      return null;
    }
  }

  // 停止HTTP服务器
  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _serverUrl = null;
      debugPrint('Web同步服务已停止');
    }
  }

  // 获取服务器状态
  static bool get isRunning => _server != null;
  static String? get serverUrl => _serverUrl;

  // 处理根路径请求
  static Response _handleIndex(Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flowm 数据同步</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .api-section {
            margin: 20px 0;
            padding: 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
        }
        .download-btn {
            display: inline-block;
            padding: 12px 24px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            transition: background 0.3s;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .download-btn:hover {
            background: #45a049;
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.3);
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            background: #4CAF50;
            border-radius: 50%;
            margin-right: 8px;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        .info-box {
            background: rgba(255, 255, 255, 0.1);
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            border-left: 4px solid #4CAF50;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔄 Flowm 数据同步</h1>

        <div class="info-box">
            <span class="status-indicator"></span>
            <strong>服务状态：</strong> 运行中
        </div>

        <div class="api-section">
            <h3>📥 下载数据库文件</h3>
            <p>点击下方按钮下载完整的 SQLite 数据库文件：</p>
            <a href="/api/getSqlFile" class="download-btn">
                📱 下载 SQLite 数据库文件
            </a>
        </div>

        <div class="api-section">
            <h3>🔧 API 接口</h3>
            <p><strong>获取数据库文件：</strong> <code>GET /api/getSqlFile</code></p>
            <p><strong>服务状态：</strong> <code>GET /api/status</code></p>
            <p><strong>数据库信息：</strong> <code>GET /api/dbInfo</code></p>
            <button onclick="checkDbInfo()" class="download-btn" style="margin-top: 10px;">🔍 检查数据库信息</button>
            <div id="dbInfo" style="margin-top: 15px; display: none;">
                <h4>📁 数据库信息</h4>
                <pre id="dbInfoContent" style="background: rgba(0,0,0,0.2); padding: 10px; border-radius: 5px; font-size: 12px; overflow-x: auto;"></pre>
            </div>
        </div>

        <script>
        async function checkDbInfo() {
            const dbInfoDiv = document.getElementById('dbInfo');
            const dbInfoContent = document.getElementById('dbInfoContent');

            try {
                const response = await fetch('/api/dbInfo');
                const data = await response.json();
                dbInfoContent.textContent = JSON.stringify(data, null, 2);
                dbInfoDiv.style.display = 'block';
            } catch (error) {
                dbInfoContent.textContent = '获取数据库信息失败: ' + error.message;
                dbInfoDiv.style.display = 'block';
            }
        }
        </script>

        <div class="info-box">
            <p><strong>注意：</strong> 请确保设备在同一局域网内访问此服务。</p>
        </div>
    </div>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  // 处理状态查询
  static Response _handleStatus(Request request) {
    return Response.ok(
      '{"status": "running", "timestamp": "${DateTime.now().toIso8601String()}"}',
      headers: {'content-type': 'application/json'},
    );
  }

  // CORS中间件
  static Handler _corsMiddleware(Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        // 处理预检请求
        return Response.ok(
          '',
          headers: _getCorsHeaders(),
        );
      }

      // 处理正常请求并添加CORS头
      final response = await innerHandler(request);
      final corsHeaders = _getCorsHeaders();

      // 合并现有响应头和CORS头
      final newHeaders = Map<String, String>.from(response.headers);
      newHeaders.addAll(corsHeaders);

      return response.change(headers: newHeaders);
    };
  }

  // 获取CORS头
  static Map<String, String> _getCorsHeaders() {
    return {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'access-control-allow-headers':
          'Content-Type, Authorization, X-Requested-With',
      'access-control-max-age': '86400',
    };
  }

  // 处理数据库信息查询
  static Future<Response> _handleDbInfo(Request request) async {
    try {
      debugPrint('接收到数据库信息请求: ${request.url}');
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = await _getDatabasePath();

      Map<String, dynamic> info = {
        'documentDirectory': directory.path,
        'detectedDbPath': dbPath,
        'timestamp': DateTime.now().toIso8601String(),
        'dbFiles': [],
      };

      // 列出所有数据库文件
      final dir = Directory(directory.path);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            final stat = await entity.stat();
            info['dbFiles'].add({
              'path': entity.path,
              'name': path.basename(entity.path),
              'size': stat.size,
              'modified': stat.modified.toIso8601String(),
            });
          }
        }
      }

      if (dbPath != null) {
        final file = File(dbPath);
        info['selectedDbExists'] = await file.exists();
        if (await file.exists()) {
          final stat = await file.stat();
          info['selectedDbSize'] = stat.size;
          info['selectedDbModified'] = stat.modified.toIso8601String();
        }
      }

      return Response.ok(
        jsonEncode(info),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: '{"error": "获取数据库信息失败: $e"}',
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // 处理SQLite文件下载请求
  static Future<Response> _handleGetSqlFile(Request request) async {
    try {
      if (kIsWeb) {
        return Response.internalServerError(
          body: '{"error": "Web平台不支持文件下载"}',
          headers: {'content-type': 'application/json'},
        );
      }

      debugPrint('开始获取数据库文件...');

      // 获取数据库文件路径
      final dbPath = await _getDatabasePath();
      debugPrint('数据库路径: $dbPath');

      if (dbPath == null) {
        final errorMsg = '{"error": "无法确定数据库文件路径"}';
        debugPrint('错误: $errorMsg');
        return Response.notFound(
          errorMsg,
          headers: {'content-type': 'application/json'},
        );
      }

      final file = File(dbPath);
      final exists = await file.exists();
      debugPrint('文件是否存在: $exists, 路径: $dbPath');

      if (!exists) {
        final errorMsg = '{"error": "数据库文件不存在: $dbPath"}';
        debugPrint('错误: $errorMsg');
        return Response.notFound(
          errorMsg,
          headers: {'content-type': 'application/json'},
        );
      }

      // 获取文件信息
      final stat = await file.stat();
      debugPrint('文件大小: ${stat.size} bytes');

      // 读取文件内容
      final bytes = await file.readAsBytes();
      final fileName = 'flowm_database.db';

      debugPrint('成功读取数据库文件，大小: ${bytes.length} bytes');

      return Response.ok(
        bytes,
        headers: {
          'content-type': 'application/octet-stream',
          'content-disposition': 'attachment; filename="$fileName"',
          'content-length': '${bytes.length}',
        },
      );
    } catch (e, stackTrace) {
      final errorMsg = '下载数据库文件失败: $e';
      debugPrint('$errorMsg\n$stackTrace');
      return Response.internalServerError(
        body: '{"error": "$errorMsg"}',
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // 获取数据库文件路径
  static Future<String?> _getDatabasePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // 尝试多种可能的数据库文件名
      final possibleNames = [
        'flowm_database.sqlite',
      ];

      for (String dbName in possibleNames) {
        final dbPath = path.join(directory.path, dbName);
        final file = File(dbPath);
        if (await file.exists()) {
          debugPrint('找到数据库文件: $dbPath');
          return dbPath;
        }
      }

      // 如果没找到，列出目录中的所有.db文件
      final dir = Directory(directory.path);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            debugPrint('发现数据库文件: ${entity.path}');
            return entity.path;
          }
        }
      }

      debugPrint('数据库目录路径: ${directory.path}');
      debugPrint('未找到数据库文件，将使用默认路径');
      return path.join(directory.path, 'app_database.db');
    } catch (e) {
      debugPrint('获取数据库路径失败: $e');
      return null;
    }
  }
}
