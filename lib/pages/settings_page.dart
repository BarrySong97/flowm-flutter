import 'package:flutter/material.dart';
import 'package:flowm/components/settings/settings_profile_card.dart';
import 'package:flowm/components/settings/settings_membership_card.dart';
import 'package:flowm/components/settings/settings_feature_grid.dart';
import 'package:flowm/components/settings/settings_data_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        ),
      ),
    );
  }
}
