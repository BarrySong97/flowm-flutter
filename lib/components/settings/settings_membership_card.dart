import 'package:flutter/material.dart';

class SettingsMembershipCard extends StatelessWidget {
  final VoidCallback onUpgradePressed;

  const SettingsMembershipCard({
    super.key,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '升级到高级会员',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '更多功能，记账更轻松',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onUpgradePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[100],
              foregroundColor: Colors.teal[700],
              elevation: .8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
            child: const Text('去开通'),
          ),
        ],
      ),
    );
  }
}
