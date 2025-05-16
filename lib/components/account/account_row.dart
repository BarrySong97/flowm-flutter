import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart'; // For Account model

class AccountRow extends StatelessWidget {
  final Account account;
  final double? percentage;
  // This boolean will help decide if the currency symbol should be shown.
  // It replaces the more complex logic of isParentRow and actualHasChildren.
  final bool showCurrencySymbolInAmount;

  const AccountRow({
    Key? key,
    required this.account,
    this.percentage,
    required this.showCurrencySymbolInAmount,
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

    String displayedAmount;
    if (showCurrencySymbolInAmount) {
      displayedAmount =
          '${account.currencySymbol}${account.amount.toStringAsFixed(2)}';
    } else {
      // Typically for parent accounts in a list where children sum up to this amount
      displayedAmount = account.amount.toStringAsFixed(2);
    }

    return Padding(
      // Ensure consistent padding for the row content
      padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                          account.name,
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
              Text(displayedAmount, style: amountStyle),
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
    );
  }
}
