import 'package:flutter/material.dart';
import 'transaction_detail_bottom_sheet.dart';
import '../../db/tables/account_table.dart';

class TransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String type;
  final Color statusColor;
  final bool isExpense;
  final String? transactionId;
  final String? fullDescription;
  final DateTime? transactionDate;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;
  final double? transactionAmount;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.statusColor = const Color(0xFF34C759), // Default to green
    this.isExpense = true,
    this.transactionId,
    this.fullDescription,
    this.transactionDate,
    this.fromAccountType,
    this.toAccountType,
    this.transactionAmount,
    this.onEdit,
    this.onCopy,
    this.onShare,
    this.onDelete,
  });

  void _showTransactionDetail(BuildContext context) {
    final formattedDate = transactionDate != null
        ? '${transactionDate!.year}年${transactionDate!.month}月${transactionDate!.day}日'
        : '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日';

    TransactionDetailBottomSheet.show(
      context: context,
      amount: amount,
      subtitle: subtitle,
      date: formattedDate,
      isExpense: isExpense,
      transactionId: transactionId,
      description: fullDescription,
      fromAccountType: fromAccountType,
      toAccountType: toAccountType,
      transactionAmount: transactionAmount,
      onEdit: onEdit,
      onCopy: onCopy,
      onShare: onShare,
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTransactionDetail(context),
      child: Container(
        color: Colors.transparent,
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
      ),
    );
  }
}
