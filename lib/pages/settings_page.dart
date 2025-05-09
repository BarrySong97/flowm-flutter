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
              // Profile card
              SettingsProfileCard(
                username: 'BarrySong4Real',
                daysCount: '1545',
                recordsCount: '9',
              ),

              // Membership upgrade card
              SettingsMembershipCard(
                onUpgradePressed: () {
                  // Handle upgrade button press
                },
              ),

              // Features grid
              SettingsFeatureGrid(
                items: [
                  SettingsFeatureItem(
                    icon: Icons.auto_awesome,
                    title: '自动记账',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.date_range,
                    title: '周期记账',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.list_alt,
                    title: '愿望清单',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.tag,
                    title: '分类关键词',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.book,
                    title: '账本管理',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.label,
                    title: '标签管理',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.category,
                    title: '分类管理',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                  SettingsFeatureItem(
                    icon: Icons.more_horiz,
                    title: '更多设置',
                    iconColor: Colors.teal,
                    onTap: () {},
                  ),
                ],
              ),

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
                    icon: Icons.backup,
                    title: '数据备份',
                    onTap: () {},
                  ),
                  SettingsDataItem(
                    icon: Icons.import_export,
                    title: '导入/导出',
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
