import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class WebDAVClient {
  final String baseUrl;
  final String username;
  final String password;
  final Duration timeout;

  WebDAVClient({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.timeout = const Duration(seconds: 30),
  });

  // 获取基础认证头
  String _getAuthHeader() {
    final credentials = '$username:$password';
    final encodedCredentials = base64.encode(utf8.encode(credentials));
    return 'Basic $encodedCredentials';
  }

  // 构建正确的 WebDAV URL
  String _buildUrl(String remotePath) {
    // 确保 baseUrl 不以 / 结尾，remotePath 不以 / 开头
    String cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String cleanRemotePath =
        remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;

    return '$cleanBaseUrl/$cleanRemotePath';
  }

  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = {
      'Authorization': _getAuthHeader(),
      'User-Agent': 'Flowm-Flutter-WebDAV-Client/1.0',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // 测试连接
  Future<bool> testConnection() async {
    try {
      // 使用 PROPFIND 方法测试连接，这是 WebDAV 的标准方法
      // 大多数 WebDAV 服务器都支持对根目录的 PROPFIND 请求
      const propfindBody = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';

      final client = http.Client();
      try {
        final request = http.Request('PROPFIND', Uri.parse(baseUrl));
        request.headers.addAll(_getHeaders(additionalHeaders: {
          'Content-Type': 'text/xml; charset=utf-8',
          'Depth': '0',
        }));
        request.body = propfindBody;

        final streamedResponse = await client.send(request).timeout(timeout);

        // PROPFIND 成功的状态码通常是 207 (Multi-Status)
        // 但有些服务器可能返回 200
        // 401 表示认证失败，403 表示权限不足但连接成功
        if (streamedResponse.statusCode == 207 ||
            streamedResponse.statusCode == 200 ||
            streamedResponse.statusCode == 403) {
          return true;
        } else if (streamedResponse.statusCode == 401) {
          throw Exception('认证失败，请检查用户名和密码');
        } else {
          throw Exception('服务器响应错误: HTTP ${streamedResponse.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // 如果 PROPFIND 也失败，尝试简单的 OPTIONS 请求
      // OPTIONS 请求通常被大多数服务器允许
      try {
        final client = http.Client();
        try {
          final request = http.Request('OPTIONS', Uri.parse(baseUrl));
          request.headers.addAll(_getHeaders());

          final streamedResponse = await client.send(request).timeout(timeout);

          // OPTIONS 请求成功，说明服务器可达且认证有效
          if (streamedResponse.statusCode >= 200 &&
              streamedResponse.statusCode < 300) {
            return true;
          } else if (streamedResponse.statusCode == 401) {
            throw Exception('认证失败，请检查用户名和密码');
          } else {
            throw Exception('连接失败: HTTP ${streamedResponse.statusCode}');
          }
        } finally {
          client.close();
        }
      } catch (optionsError) {
        // 如果两种方法都失败，抛出原始错误
        throw Exception('连接测试失败: $e');
      }
    }
  }

  // 上传文件
  Future<bool> uploadFile(String remotePath, File localFile) async {
    try {
      if (!await localFile.exists()) {
        throw Exception('本地文件不存在: ${localFile.path}');
      }

      final url = Uri.parse(_buildUrl(remotePath));

      // 确保父目录存在
      try {
        await ensureDirectoryExists(remotePath);
      } catch (e) {
        // 继续尝试上传，可能目录已存在
        print(e);
      }

      final fileBytes = await localFile.readAsBytes();

      final response = await http
          .put(
            url,
            headers: _getHeaders(additionalHeaders: {
              'Content-Type': 'application/octet-stream',
              'Content-Length': fileBytes.length.toString(),
            }),
            body: fileBytes,
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('上传失败: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('上传文件失败: $e');
    }
  }

  // 下载文件
  Future<Uint8List> downloadFile(String remotePath) async {
    try {
      final url = Uri.parse(_buildUrl(remotePath));

      final response = await http
          .get(
            url,
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('下载文件失败: $e');
    }
  }

  // 获取文件信息 (使用 PROPFIND)
  Future<WebDAVFileInfo?> getFileInfo(String remotePath) async {
    try {
      final url = Uri.parse(_buildUrl(remotePath));

      const propfindBody = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getlastmodified/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';

      final client = http.Client();
      try {
        final request = http.Request('PROPFIND', url);
        request.headers.addAll(_getHeaders(additionalHeaders: {
          'Content-Type': 'text/xml; charset=utf-8',
          'Depth': '0',
        }));
        request.body = propfindBody;

        final streamedResponse = await client.send(request).timeout(timeout);
        final responseBody = await streamedResponse.stream.bytesToString();
        print(responseBody);

        if (streamedResponse.statusCode == 207) {
          return _parseFileInfoFromPropfind(responseBody, remotePath);
        } else if (streamedResponse.statusCode == 404) {
          return null; // 文件不存在
        } else if (streamedResponse.statusCode == 409) {
          // 409 错误通常表示父目录不存在，文件也不存在
          return null;
        } else {
          throw Exception(
              '获取文件信息失败: HTTP ${streamedResponse.statusCode} - $responseBody');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('获取文件信息失败: $e');
    }
  }

  // 解析 PROPFIND 响应
  WebDAVFileInfo? _parseFileInfoFromPropfind(
      String xmlBody, String remotePath) {
    try {
      // 支持多种命名空间前缀格式的XML解析
      final lastModifiedRegex =
          RegExp(r'<[dD]:getlastmodified[^>]*>([^<]+)</[dD]:getlastmodified>');
      final contentLengthRegex =
          RegExp(r'<[dD]:getcontentlength[^>]*>([^<]+)</[dD]:getcontentlength>');

      final lastModifiedMatch = lastModifiedRegex.firstMatch(xmlBody);
      final contentLengthMatch = contentLengthRegex.firstMatch(xmlBody);

      if (lastModifiedMatch != null && contentLengthMatch != null) {
        final lastModifiedStr = lastModifiedMatch.group(1)!;
        final contentLength = int.parse(contentLengthMatch.group(1)!);

        // 解析RFC2822格式的日期
        final lastModified = HttpDate.parse(lastModifiedStr);

        return WebDAVFileInfo(
          path: remotePath,
          size: contentLength,
          lastModified: lastModified,
        );
      }

      return null;
    } catch (e) {
      throw Exception('解析文件信息失败: $e');
    }
  }

  // 创建目录（如果不存在）
  Future<bool> createDirectory(String remotePath) async {
    try {
      final url = Uri.parse(_buildUrl(remotePath));

      final client = http.Client();
      try {
        final request = http.Request('MKCOL', url);
        request.headers.addAll(_getHeaders());

        final streamedResponse = await client.send(request).timeout(timeout);

        if (streamedResponse.statusCode == 201) {
          return true;
        } else if (streamedResponse.statusCode == 405) {
          return true;
        } else {
          final responseBody = await streamedResponse.stream.bytesToString();
          throw Exception(
              '创建目录失败: HTTP ${streamedResponse.statusCode} - $responseBody');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('创建目录失败: $e');
    }
  }

  // 确保文件的父目录存在
  Future<void> ensureDirectoryExists(String remotePath) async {
    final pathSegments = remotePath.split('/');

    if (pathSegments.length <= 1) {
      return; // 根目录或无需创建目录
    }

    // 逐级创建父目录
    String currentPath = '';
    for (int i = 0; i < pathSegments.length - 1; i++) {
      if (pathSegments[i].isNotEmpty) {
        currentPath += '/${pathSegments[i]}';
        final dirPath = currentPath.substring(1); // 移除开头的 /
        try {
          await createDirectory(dirPath);
        } catch (e) {
          // 忽略目录创建失败的错误，可能已经存在
        }
      }
    }
  }

  // 检查文件是否存在
  Future<bool> fileExists(String remotePath) async {
    final fileInfo = await getFileInfo(remotePath);
    return fileInfo != null;
  }
}

// WebDAV 文件信息类
class WebDAVFileInfo {
  final String path;
  final int size;
  final DateTime lastModified;

  WebDAVFileInfo({
    required this.path,
    required this.size,
    required this.lastModified,
  });

  @override
  String toString() {
    return 'WebDAVFileInfo(path: $path, size: $size, lastModified: $lastModified)';
  }
}
