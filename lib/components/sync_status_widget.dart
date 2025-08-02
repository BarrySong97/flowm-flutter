import 'package:flutter/material.dart';
import '../utils/file_time_utils.dart';

/// 同步状态信息类
class SyncStatusInfo {
  final DateTime? localFileTime;
  final DateTime? remoteFileTime;
  final DateTime? lastSyncTime;
  final int? localFileSize;
  final int? remoteFileSize;
  final String statusMessage;
  final bool isLoading;

  const SyncStatusInfo({
    this.localFileTime,
    this.remoteFileTime,
    this.lastSyncTime,
    this.localFileSize,
    this.remoteFileSize,
    this.statusMessage = '未知状态',
    this.isLoading = false,
  });

  /// copyWith方法
  SyncStatusInfo copyWith({
    DateTime? localFileTime,
    DateTime? remoteFileTime,
    DateTime? lastSyncTime,
    int? localFileSize,
    int? remoteFileSize,
    String? statusMessage,
    bool? isLoading,
  }) {
    return SyncStatusInfo(
      localFileTime: localFileTime ?? this.localFileTime,
      remoteFileTime: remoteFileTime ?? this.remoteFileTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      localFileSize: localFileSize ?? this.localFileSize,
      remoteFileSize: remoteFileSize ?? this.remoteFileSize,
      statusMessage: statusMessage ?? this.statusMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 判断哪个文件更新
  SyncFileStatus get fileStatus {
    if (localFileTime == null && remoteFileTime == null) {
      return SyncFileStatus.noFiles;
    }
    if (localFileTime == null) {
      return SyncFileStatus.remoteOnly;
    }
    if (remoteFileTime == null) {
      return SyncFileStatus.localOnly;
    }

    final comparison = FileTimeUtils.compareTime(localFileTime, remoteFileTime);
    if (comparison > 0) {
      return SyncFileStatus.localNewer;
    } else if (comparison < 0) {
      return SyncFileStatus.remoteNewer;
    } else {
      return SyncFileStatus.synchronized;
    }
  }
}

/// 文件同步状态枚举
enum SyncFileStatus {
  noFiles,      // 无文件
  localOnly,    // 仅本地有文件
  remoteOnly,   // 仅服务器有文件
  localNewer,   // 本地更新
  remoteNewer,  // 服务器更新
  synchronized, // 已同步
}

/// 同步状态显示组件
class SyncStatusWidget extends StatelessWidget {
  final SyncStatusInfo statusInfo;

  const SyncStatusWidget({
    super.key,
    required this.statusInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '同步状态',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (statusInfo.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeInfoSection(),
            const SizedBox(height: 12),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoSection() {
    return Column(
      children: [
        _buildTimeRow(
          icon: Icons.smartphone,
          label: '本地文件',
          time: statusInfo.localFileTime,
          size: statusInfo.localFileSize,
          isNewer: statusInfo.fileStatus == SyncFileStatus.localNewer,
        ),
        const SizedBox(height: 8),
        _buildTimeRow(
          icon: Icons.cloud,
          label: '服务器文件',
          time: statusInfo.remoteFileTime,
          size: statusInfo.remoteFileSize,
          isNewer: statusInfo.fileStatus == SyncFileStatus.remoteNewer,
        ),
        const SizedBox(height: 8),
        _buildTimeRow(
          icon: Icons.sync_alt,
          label: '上次同步',
          time: statusInfo.lastSyncTime,
          isSync: true,
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    DateTime? time,
    int? size,
    bool isNewer = false,
    bool isSync = false,
  }) {
    Color getStatusColor() {
      if (isSync) return Colors.blue.shade600;
      if (time == null) return Colors.grey.shade600;
      if (isNewer) return Colors.green.shade600;
      return Colors.orange.shade600;
    }

    String getStatusIcon() {
      if (isSync) return '⏰';
      if (time == null) return '❌';
      if (isNewer) return '🟢';
      return '🟡';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: getStatusColor()),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          getStatusIcon(),
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time != null 
                    ? FileTimeUtils.formatDateTime(time)
                    : '无文件',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isNewer ? FontWeight.w600 : FontWeight.normal,
                  color: getStatusColor(),
                ),
              ),
              if (time != null && !isSync)
                Text(
                  '${FileTimeUtils.getTimeAgo(time)}${size != null ? ' • ${FileTimeUtils.formatFileSize(size)}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusBorderColor()),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (statusInfo.statusMessage.isNotEmpty)
                  Text(
                    statusInfo.statusMessage,
                    style: TextStyle(
                      color: _getStatusColor().withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle() {
    switch (statusInfo.fileStatus) {
      case SyncFileStatus.noFiles:
        return '未找到数据文件';
      case SyncFileStatus.localOnly:
        return '本地有未同步更改';
      case SyncFileStatus.remoteOnly:
        return '服务器有新数据';
      case SyncFileStatus.localNewer:
        return '本地有未同步更改';
      case SyncFileStatus.remoteNewer:
        return '服务器有新数据';
      case SyncFileStatus.synchronized:
        return '数据已同步';
    }
  }

  IconData _getStatusIcon() {
    switch (statusInfo.fileStatus) {
      case SyncFileStatus.noFiles:
        return Icons.warning_outlined;
      case SyncFileStatus.localOnly:
      case SyncFileStatus.localNewer:
        return Icons.cloud_upload_outlined;
      case SyncFileStatus.remoteOnly:
      case SyncFileStatus.remoteNewer:
        return Icons.cloud_download_outlined;
      case SyncFileStatus.synchronized:
        return Icons.check_circle_outline;
    }
  }

  Color _getStatusColor() {
    switch (statusInfo.fileStatus) {
      case SyncFileStatus.noFiles:
        return Colors.orange.shade700;
      case SyncFileStatus.localOnly:
      case SyncFileStatus.localNewer:
        return Colors.blue.shade700;
      case SyncFileStatus.remoteOnly:
      case SyncFileStatus.remoteNewer:
        return Colors.green.shade700;
      case SyncFileStatus.synchronized:
        return Colors.green.shade700;
    }
  }

  Color _getStatusBackgroundColor() {
    switch (statusInfo.fileStatus) {
      case SyncFileStatus.noFiles:
        return Colors.orange.shade50;
      case SyncFileStatus.localOnly:
      case SyncFileStatus.localNewer:
        return Colors.blue.shade50;
      case SyncFileStatus.remoteOnly:
      case SyncFileStatus.remoteNewer:
        return Colors.green.shade50;
      case SyncFileStatus.synchronized:
        return Colors.green.shade50;
    }
  }

  Color _getStatusBorderColor() {
    switch (statusInfo.fileStatus) {
      case SyncFileStatus.noFiles:
        return Colors.orange.shade200;
      case SyncFileStatus.localOnly:
      case SyncFileStatus.localNewer:
        return Colors.blue.shade200;
      case SyncFileStatus.remoteOnly:
      case SyncFileStatus.remoteNewer:
        return Colors.green.shade200;
      case SyncFileStatus.synchronized:
        return Colors.green.shade200;
    }
  }
}