import 'package:flowm/shared/logging/app_logger.dart';
import 'dart:io';

/// 文件时间处理工具类
class FileTimeUtils {
  /// 格式化日期时间为用户友好的格式
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 计算时间差并返回友好的描述
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDateTime(dateTime);
    }
  }

  /// 比较两个时间，返回哪个更新
  /// 返回值：1 表示第一个更新，-1 表示第二个更新，0 表示相同
  static int compareTime(DateTime? time1, DateTime? time2) {
    if (time1 == null && time2 == null) return 0;
    if (time1 == null) return -1;
    if (time2 == null) return 1;

    return time1.compareTo(time2);
  }

  /// 获取本地数据库文件的修改时间
  static Future<DateTime?> getLocalDatabaseTime(String databasePath) async {
    try {
      final file = File(databasePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
      return null;
    } catch (e) {
      AppLogger.debug('[FileTimeUtils] 获取本地数据库时间失败: $e');
      return null;
    }
  }

  /// 获取文件大小的友好显示
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
