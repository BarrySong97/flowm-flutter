import 'package:flutter/material.dart';
import '../services/auto_sync_service.dart';
import '../services/database_sync_service.dart';

/// 同步对话框统一样式助手类
class SyncDialogHelper {
  
  /// 构建智能推荐按钮 - 根据建议高亮显示
  static Widget buildRecommendedButton({
    required String text,
    required VoidCallback onPressed,
    required bool isRecommended,
    required Color recommendedColor,
    required IconData icon,
    bool isElevated = false,
  }) {
    if (isRecommended) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: recommendedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 3,
          shadowColor: recommendedColor.withValues(alpha: 0.5),
        ),
      );
    } else if (isElevated) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }

  /// 构建初始同步按钮（用于首次配置）
  static Widget buildInitialSyncButton({
    required String text,
    required VoidCallback onPressed,
    required SyncDirection recommendation,
    required SyncDirection buttonType,
    required IconData icon,
  }) {
    final isRecommended = recommendation == buttonType;
    Color recommendedColor = Colors.blue;
    
    switch (buttonType) {
      case SyncDirection.upload:
        recommendedColor = Colors.green;
        break;
      case SyncDirection.download:
        recommendedColor = Colors.orange;
        break;
      default:
        recommendedColor = Colors.blue;
    }

    if (isRecommended) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text, 
          style: const TextStyle(fontWeight: FontWeight.w600)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: recommendedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 3,
          shadowColor: recommendedColor.withValues(alpha: 0.5),
        ),
      );
    } else if (buttonType == SyncDirection.download) {
      // 下载按钮默认是ElevatedButton
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }

  /// 构建冲突解决按钮
  static Widget buildConflictButton({
    required String text,
    required VoidCallback onPressed,
    required bool isRecommended,
    required ConflictButtonType buttonType,
    bool isElevated = false,
  }) {
    Color recommendedColor = Colors.blue;
    IconData icon = Icons.check;
    
    switch (buttonType) {
      case ConflictButtonType.useLocal:
        recommendedColor = Colors.green;
        icon = Icons.cloud_upload;
        break;
      case ConflictButtonType.useRemote:
        recommendedColor = Colors.blue;
        icon = Icons.cloud_download;
        break;
      case ConflictButtonType.cancel:
        return TextButton(
          onPressed: onPressed,
          child: Text(text),
        );
    }

    if (isRecommended) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: recommendedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 3,
          shadowColor: recommendedColor.withValues(alpha: 0.5),
        ),
      );
    } else if (isElevated || buttonType == ConflictButtonType.useLocal) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }

  /// 构建推荐信息容器
  static Widget buildRecommendationContainer({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件信息对比容器
  static Widget buildFileInfoContainer({
    required SyncConflict conflict,
    required bool Function(SyncConflict) localIsNewerChecker,
    required bool Function(SyncConflict) remoteIsNewerChecker,
    required String Function(DateTime) dateFormatter,
    required String Function(int) sizeFormatter,
  }) {
    final localIsNewer = localIsNewerChecker(conflict);
    final remoteIsNewer = remoteIsNewerChecker(conflict);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, 
                   size: 16, 
                   color: localIsNewer ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Text(
                '本地文件: ${dateFormatter(conflict.localModified)}',
                style: TextStyle(
                  fontWeight: localIsNewer ? FontWeight.w600 : FontWeight.normal
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '文件大小: ${sizeFormatter(conflict.localSize)}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.cloud, 
                   size: 16, 
                   color: remoteIsNewer ? Colors.blue : Colors.grey),
              const SizedBox(width: 4),
              Text(
                '服务器文件: ${dateFormatter(conflict.remoteModified)}',
                style: TextStyle(
                  fontWeight: remoteIsNewer ? FontWeight.w600 : FontWeight.normal
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '文件大小: ${sizeFormatter(conflict.remoteSize)}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 获取冲突推荐信息
  static ConflictRecommendation getConflictRecommendation(SyncConflict conflict) {
    final localIsNewer = conflict.localModified.isAfter(conflict.remoteModified);
    final remoteIsNewer = conflict.remoteModified.isAfter(conflict.localModified);
    
    if (localIsNewer) {
      return ConflictRecommendation(
        message: '建议：本地文件更新，推荐使用本地版本',
        color: Colors.green,
        icon: Icons.upload,
        recommendedAction: ConflictButtonType.useLocal,
      );
    } else if (remoteIsNewer) {
      return ConflictRecommendation(
        message: '建议：服务器文件更新，推荐使用服务器版本',
        color: Colors.blue,
        icon: Icons.download,
        recommendedAction: ConflictButtonType.useRemote,
      );
    } else {
      return ConflictRecommendation(
        message: '提示：两个文件修改时间相同，请根据内容选择',
        color: Colors.orange,
        icon: Icons.help_outline,
        recommendedAction: null,
      );
    }
  }

  /// 获取同步方向推荐信息
  static SyncRecommendation getSyncRecommendation(SyncDirection direction) {
    switch (direction) {
      case SyncDirection.download:
        return SyncRecommendation(
          message: '建议：检测到服务器有新数据，推荐下载',
          color: Colors.orange,
          icon: Icons.cloud_download,
        );
      case SyncDirection.upload:
        return SyncRecommendation(
          message: '建议：检测到本地有数据，推荐上传',
          color: Colors.green,
          icon: Icons.cloud_upload,
        );
      case SyncDirection.conflict:
        return SyncRecommendation(
          message: '注意：本地和服务器都有数据，请谨慎选择',
          color: Colors.red,
          icon: Icons.warning,
        );
      case SyncDirection.none:
        return SyncRecommendation(
          message: '提示：数据已同步，可选择跳过',
          color: Colors.blue,
          icon: Icons.check_circle,
        );
    }
  }
}

/// 冲突按钮类型
enum ConflictButtonType {
  cancel,
  useLocal,
  useRemote,
}

/// 冲突推荐信息
class ConflictRecommendation {
  final String message;
  final Color color;
  final IconData icon;
  final ConflictButtonType? recommendedAction;

  const ConflictRecommendation({
    required this.message,
    required this.color,
    required this.icon,
    this.recommendedAction,
  });
}

/// 同步推荐信息
class SyncRecommendation {
  final String message;
  final Color color;
  final IconData icon;

  const SyncRecommendation({
    required this.message,
    required this.color,
    required this.icon,
  });
}