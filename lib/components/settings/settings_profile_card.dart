import 'package:flutter/material.dart';

class SettingsProfileCard extends StatelessWidget {
  final String username;
  final String daysCount;
  final String recordsCount;

  const SettingsProfileCard({
    super.key,
    required this.username,
    required this.daysCount,
    required this.recordsCount,
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
        spacing: 12,
        children: [
          // Profile image
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              // shape: BoxShape.circle,
              borderRadius: BorderRadius.circular(6.0),
              color: Colors.grey[200],
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
          // Username
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'BarrySong97@gmail.com',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // User stats
        ],
      ),
    );
  }
}
