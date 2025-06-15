import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';

class AccountSelectorField extends StatelessWidget {
  final String label;
  final Account? selectedAccount;
  final Function(Account?) onAccountChanged;
  final String hintText;
  final AccountSelectorType? defaultAccountType;

  const AccountSelectorField({
    super.key,
    required this.label,
    this.selectedAccount,
    required this.onAccountChanged,
    this.hintText = '请选择账户',
    this.defaultAccountType,
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
                        Text(
                          '${selectedAccount!.currencySymbol}${selectedAccount!.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
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
}
