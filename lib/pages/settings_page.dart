import 'package:flutter/material.dart';
import 'package:flowm/components/settings/settings_data_section.dart';
import 'package:go_router/go_router.dart';

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
              SettingsDataSection(
                title: '关于',
                items: [
                  SettingsDataItem(
                    icon: Icons.info_outline,
                    title: '版本',
                    subtitle: '1.0.0',
                    onTap: () {
                      context.pushNamed('version');
                    },
                  ),
                  SettingsDataItem(
                    icon: Icons.person,
                    title: '开发者',
                    subtitle: '4RE△L Studio',
                    showArrow: false,
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
