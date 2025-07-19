import 'package:flutter/material.dart';
import 'package:flowm/components/settings/settings_data_section.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String version = '加载中...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

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
                    subtitle: version,
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
