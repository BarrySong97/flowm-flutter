import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/utils/transaction_type_map.dart';

class AccountSelectorField extends StatelessWidget {
  final String label;
  final Account? selectedAccount;
  final Function(Account?) onAccountChanged;
  final String hintText;
  final AccountSelectorType? defaultAccountType;
  final double transactionAmount;
  final bool isFromAccount;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;

  const AccountSelectorField({
    super.key,
    required this.label,
    this.selectedAccount,
    required this.onAccountChanged,
    this.hintText = '请选择账户',
    this.defaultAccountType,
    this.transactionAmount = 0.0,
    this.isFromAccount = false,
    this.fromAccountType,
    this.toAccountType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showAccountSelector(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                if (selectedAccount?.icon != null) ...[
                  Icon(
                    selectedAccount!.icon,
                    size: 24,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAccount?.name ?? hintText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: selectedAccount != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                      if (selectedAccount != null) ...[
                        const SizedBox(height: 2),
                        _buildBalanceText(context),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAccountSelector(BuildContext context) async {
    final result = await AccountSelectorBottomSheet.show(
      context,
      title: label,
      selectedAccount: selectedAccount,
      defaultAccountType: defaultAccountType,
    );

    if (result != null) {
      onAccountChanged(result);
    }
  }

  Widget _buildBalanceText(BuildContext context) {
    if (selectedAccount == null) return const SizedBox.shrink();

    final balanceChange = getBalanceChange(
      isFromAccount: isFromAccount,
      fromAccountType: fromAccountType,
      toAccountType: toAccountType,
    );

    final originalAmount = selectedAccount!.amount;
    final newAmount = originalAmount + balanceChange * transactionAmount;

    if (transactionAmount == 0.0) {
      return Text(
        '${selectedAccount!.currencySymbol}${originalAmount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    }

    String operator;
    Color changeColor;

    if (balanceChange > 0) {
      operator = '+';
      changeColor = Colors.green;
    } else if (balanceChange < 0) {
      operator = '-';
      changeColor = Colors.red;
    } else {
      operator = '±'; // Should not happen with current logic
      changeColor = Colors.grey;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontFamily:
              Theme.of(context).textTheme.bodyMedium?.fontFamily, // 保证字体一致性
        ),
        children: [
          TextSpan(
              text:
                  '余额 ${selectedAccount!.currencySymbol}${originalAmount.toStringAsFixed(2)} '),
          TextSpan(
            text: '$operator ${transactionAmount.toStringAsFixed(2)}',
            style: TextStyle(color: changeColor),
          ),
          TextSpan(text: ' = ${newAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
