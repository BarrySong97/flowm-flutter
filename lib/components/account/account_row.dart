import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart'; // For Account model
import 'package:flowm/db/tables/account_table.dart' show AccountType;

class AccountRow extends StatelessWidget {
  final Account account;
  final double? percentage;
  // This boolean will help decide if the currency symbol should be shown.
  // It replaces the more complex logic of isParentRow and actualHasChildren.
  final bool showCurrencySymbolInAmount;
  final void Function(Account account)? onTap;

  const AccountRow({
    Key? key,
    required this.account,
    this.percentage,
    required this.showCurrencySymbolInAmount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = 15.0;
    final TextStyle nameStyle = TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87);
    final TextStyle amountStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.black87);

    // 获取用户友好的金额显示
    final userFriendlyAmount =
        _getUserFriendlyAmount(account.amount, account.type);

    String displayedAmount;
    if (showCurrencySymbolInAmount) {
      displayedAmount = userFriendlyAmount.toStringAsFixed(2);
    } else {
      // Typically for parent accounts in a list where children sum up to this amount
      displayedAmount = userFriendlyAmount.toStringAsFixed(2);
    }

    return Padding(
      // Ensure consistent padding for the row content
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: InkWell(
        onTap: () => onTap?.call(account),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (account.icon != null) ...[
                    Icon(account.icon, color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${account.name}',
                            style: nameStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (percentage != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '(${percentage!.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('${account.currencySymbol}$displayedAmount',
                    style: amountStyle),
                // Conditional spacing to align with potential expansion arrow in AccountItem
                // If not showing currency (parent summary) or if it's a simple item,
                // we might not need trailing space if there's no expansion icon.
                // For now, this mimics the original _buildAccountRow's implicit spacing.
                if (showCurrencySymbolInAmount ||
                    (account.children == null || account.children!.isEmpty))
                  const SizedBox(width: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取用户友好的金额显示
  /// 收入和负债账户显示绝对值，其他账户按原值显示
  double _getUserFriendlyAmount(double amount, AccountType accountType) {
    switch (accountType) {
      case AccountType.INCOME:
      case AccountType.LIABILITY:
        return amount.abs(); // 显示绝对值
      case AccountType.ASSET:
      case AccountType.EQUITY:
      case AccountType.EXPENSE:
        return amount; // 按原值显示
    }
  }
}
