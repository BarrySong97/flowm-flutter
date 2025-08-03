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
  final String statusTitle; // 新增：状态标题，由外部提供

  const SyncStatusInfo({
    this.localFileTime,
    this.remoteFileTime,
    this.lastSyncTime,
    this.localFileSize,
    this.remoteFileSize,
    this.statusMessage = '未知状态',
    this.statusTitle = '检查中...', // 默认状态标题
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
    String? statusTitle,
    bool? isLoading,
  }) {
    return SyncStatusInfo(
      localFileTime: localFileTime ?? this.localFileTime,
      remoteFileTime: remoteFileTime ?? this.remoteFileTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      localFileSize: localFileSize ?? this.localFileSize,
      remoteFileSize: remoteFileSize ?? this.remoteFileSize,
      statusMessage: statusMessage ?? this.statusMessage,
      statusTitle: statusTitle ?? this.statusTitle,
      isLoading: isLoading ?? this.isLoading,
    );
  }
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
        ),
        const SizedBox(height: 8),
        _buildTimeRow(
          icon: Icons.cloud,
          label: '服务器文件',
          time: statusInfo.remoteFileTime,
          size: statusInfo.remoteFileSize,
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
    bool isSync = false,
  }) {
    Color getStatusColor() {
      if (isSync) return Colors.blue.shade600;
      if (time == null) return Colors.grey.shade600;
      return Colors.grey.shade700;
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
    // 根据状态消息确定显示样式
    Color statusColor = Colors.blue.shade700;
    Color backgroundColor = Colors.blue.shade50;
    Color borderColor = Colors.blue.shade200;
    IconData statusIcon = Icons.info_outline;
    
    // 根据关键词判断状态类型
    final message = statusInfo.statusMessage.toLowerCase();
    if (message.contains('错误') || message.contains('失败')) {
      statusColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      statusIcon = Icons.error_outline;
    } else if (message.contains('上传') || message.contains('本地')) {
      statusColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      statusIcon = Icons.cloud_upload_outlined;
    } else if (message.contains('下载') || message.contains('服务器')) {
      statusColor = Colors.orange.shade700;
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      statusIcon = Icons.cloud_download_outlined;
    } else if (message.contains('已同步') || message.contains('无需')) {
      statusColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusInfo.statusTitle,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (statusInfo.statusMessage.isNotEmpty)
                  Text(
                    statusInfo.statusMessage,
                    style: TextStyle(
                      color: statusColor.withValues(alpha: 0.8),
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
}