import 'package:flutter/material.dart';

class SettingsDataItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final Widget? customContent;

  SettingsDataItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.customContent,
  });
}

class SettingsDataSection extends StatelessWidget {
  final String title;
  final List<SettingsDataItem> items;

  const SettingsDataSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 56,
                endIndent: 0,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        item.icon,
                        color: Colors.black87,
                      ),
                      title: Text(item.title),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: item.trailing ??
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                      onTap: item.onTap,
                    ),
                    if (item.customContent != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 8),
                        child: item.customContent!,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
