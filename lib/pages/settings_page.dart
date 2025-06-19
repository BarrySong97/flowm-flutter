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

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
