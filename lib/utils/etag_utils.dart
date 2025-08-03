import 'dart:convert';

/// WebDAV ETag 处理工具类
/// 用于标准化、验证和比较 ETag 值
class ETagUtils {
  /// 标准化 ETag 格式
  /// 移除引号，处理 base64 padding
  static String normalizeEtag(String? etag) {
    if (etag == null || etag.isEmpty) return '';
    
    // 1. 移除首尾引号
    String normalized = etag.replaceAll(RegExp(r'^"|"$'), '');
    
    // 2. 如果是空字符串，直接返回
    if (normalized.isEmpty) return '';
    
    // 3. 处理 base64 padding（如果看起来像 base64）
    if (RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(normalized)) {
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
    }
    
    return normalized;
  }
  
  /// 检查 ETag 是否有效
  static bool isValidEtag(String? etag) {
    if (etag == null || etag.isEmpty) return false;
    final normalized = normalizeEtag(etag);
    return normalized.isNotEmpty && normalized != '""' && normalized != '"';
  }
  
  /// 比较两个 ETag 是否相同
  static bool etagEquals(String? etag1, String? etag2) {
    return normalizeEtag(etag1) == normalizeEtag(etag2);
  }
  
  /// 从 WebDAV 响应中提取 ETag
  static String? extractEtagFromWebDAVResponse(String xmlResponse) {
    final etagRegex = RegExp(r'<[dD]:getetag[^>]*>([^<]+)</[dD]:getetag>');
    final match = etagRegex.firstMatch(xmlResponse);
    return match?.group(1);
  }
  
  /// 将 ETag 转换为十六进制字符串（用于调试和日志）
  static String? etagToHex(String? etag) {
    if (!isValidEtag(etag)) return null;
    
    final normalized = normalizeEtag(etag);
    try {
      final bytes = base64.decode(normalized);
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      // 如果不是 base64 格式，直接返回原值
      return normalized;
    }
  }
}