import 'package:flutter/material.dart';

class TransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String type;
  final Color statusColor;
  final bool isExpense;

  const TransactionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.statusColor = const Color(0xFF34C759), // Default to green
    this.isExpense = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12.0),

          // Transaction Details Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          // Amount Details Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                type,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
