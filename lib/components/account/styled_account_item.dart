import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting

// Data model for the styled account item
class StyledAccount {
  final String name;
  final double rawAmount; // The raw numeric amount
  final String currencySymbol;
  final IconData iconData;
  final Color leadingColor;
  final String percentageText; // e.g., "94%"

  StyledAccount({
    required this.name,
    required this.rawAmount,
    this.currencySymbol = '\$', // Default to dollar
    required this.iconData,
    required this.leadingColor,
    required this.percentageText,
  });

  // Helper to format amount into M/K
  String get formattedAmount {
    if (rawAmount.abs() >= 1000000) {
      // 6位数及以上才格式化
      return '${currencySymbol}${(rawAmount / 1000000).toStringAsFixed(2)}M';
    } else {
      return '${currencySymbol}${NumberFormat('#,##0.00', 'zh_CN').format(rawAmount)}';
    }
  }
}

class StyledAccountItem extends StatelessWidget {
  final StyledAccount account;
  final VoidCallback? onTap;

  const StyledAccountItem({
    Key? key,
    required this.account,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 0), // No horizontal padding here, list will handle
        child: Row(
          children: [
            // Colored square
            Container(
              width: 10.0, // Changed width for a square
              height: 10.0, // Changed height for a square
              decoration: BoxDecoration(
                color: account.leadingColor,
                // borderRadius: BorderRadius.circular(2), // Optional: if you want slightly rounded square corners
              ),
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500, // Medium weight
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Amount (formatted)
            Text(
              account.formattedAmount,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500, // Medium weight
                  color: Colors.black87),
            ),

            // Percentage
            Container(
              width: 45, // Fixed width for alignment
              alignment: Alignment.centerRight,
              child: Text(
                account.percentageText,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 8), // Add some spacing before the arrow

            // Right arrow icon
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
