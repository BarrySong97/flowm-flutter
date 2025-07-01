import 'package:flowm/db/tables/account_table.dart';
import 'package:flutter/material.dart';
import 'package:flowm/components/settings/settings_profile_card.dart';
import 'package:flowm/components/settings/settings_membership_card.dart';
import 'package:flowm/components/settings/settings_feature_grid.dart';
import 'package:flowm/components/settings/settings_data_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/db/app_database.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/snackbar_utils.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flowm/state/web_sync/web_sync_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webSyncState = ref.watch(webSyncProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 12,
            children: [
              // Data management section
              SettingsDataSection(
                title: '数据管理',
                items: [
                  SettingsDataItem(
                    icon: Icons.cloud_sync,
                    title: '云同步',
                    subtitle: '未开启，数据仅存本地',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '未开启，数据仅存本地',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                    onTap: () {},
                  ),
                  // Web同步数据功能
                  SettingsDataItem(
                    icon: Icons.wifi,
                    title: 'Web同步数据',
                    subtitle: webSyncState.isRunning
                        ? '服务运行中，局域网可访问'
                        : '启动HTTP服务，局域网共享数据',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (webSyncState.isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: webSyncState.isRunning
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          webSyncState.isRunning ? '运行中' : '未启动',
                          style: TextStyle(
                            color: webSyncState.isRunning
                                ? Colors.green[600]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                    onTap: () => _showWebSyncBottomSheet(context, ref),
                    customContent: webSyncState.isRunning &&
                            webSyncState.serverUrl != null
                        ? Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.link,
                                        size: 16, color: Colors.blue[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '访问地址:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: webSyncState.serverUrl!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('已复制访问地址到剪贴板')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Colors.blue[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            webSyncState.serverUrl!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.copy,
                                            size: 14, color: Colors.blue[600]),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '点击地址可复制到剪贴板',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  SettingsDataItem(
                    icon: Icons.import_export,
                    title: '导入/导出',
                    onTap: () {},
                  ),
                ],
              ),
              SettingsDataSection(
                title: '关于',
                items: [
                  SettingsDataItem(
                    icon: Icons.cloud_sync,
                    title: '关于我们',
                    subtitle: '版本号：1.0.0',
                    onTap: () {},
                  ),
                  SettingsDataItem(
                    icon: Icons.help_outline,
                    title: '使用说明',
                    onTap: () {},
                  ),
                ],
              ),
              SettingsDataSection(
                title: '快捷指令',
                items: [
                  SettingsDataItem(
                    icon: Icons.shortcut,
                    title: 'AI记账指令',
                    subtitle: '点击下载AI记账快捷指令',
                    onTap: () => {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWebSyncBottomSheet(BuildContext context, WidgetRef ref) {
    final webSyncState = ref.read(webSyncProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(Icons.wifi, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Web同步数据',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 功能说明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          '功能说明',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 启动后将在局域网内提供HTTP服务\n'
                      '• 其他设备可通过访问URL下载数据库文件\n'
                      '• 仅在同一WiFi网络下可访问\n'
                      '• 包含完整的SQLite数据库数据',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 状态显示和操作按钮
              Consumer(
                builder: (context, ref, child) {
                  final currentState = ref.watch(webSyncProvider);

                  return Column(
                    children: [
                      // 当前状态
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: currentState.isRunning
                              ? Colors.green[50]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentState.isRunning
                                ? Colors.green[200]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: currentState.isRunning
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentState.isRunning ? '服务运行中' : '服务未启动',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: currentState.isRunning
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (currentState.error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentState.error!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // 操作按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: currentState.isLoading
                              ? null
                              : () async {
                                  if (currentState.isRunning) {
                                    await ref
                                        .read(webSyncProvider.notifier)
                                        .stopServer();
                                  } else {
                                    await ref
                                        .read(webSyncProvider.notifier)
                                        .startServer();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentState.isRunning
                                ? Colors.red[500]
                                : Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: currentState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  currentState.isRunning ? '停止服务' : '启动服务',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
