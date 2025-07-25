import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flowm/utils/account_transaction_validator.dart';

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
  final bool isEditMode;

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
    this.isEditMode = false,
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

    final originalAmount = selectedAccount!.amount;
    
    // 交易表达式中的余额显示：负债账户显示原值
    final displayAmount = _getTransactionExpressionAmount(originalAmount, selectedAccount!.type);

    if (transactionAmount == 0.0) {
      return Text(
        '${selectedAccount!.currencySymbol}${displayAmount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    }

    final balanceChange = getBalanceChange(
      isFromAccount: isFromAccount,
      fromAccountType: fromAccountType,
      toAccountType: toAccountType,
    );

    if (balanceChange == 0) {
      return Text(
        '${selectedAccount!.currencySymbol}${displayAmount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    }

    // 使用统一的符号显示逻辑，传入对手方账户类型
    String operator = AccountTransactionValidator.getAccountSymbol(
      accountType: selectedAccount!.type,
      isFromAccount: isFromAccount,
      counterpartAccountType: isFromAccount ? toAccountType : fromAccountType,
    );
    
    Color changeColor = operator == '+' ? Colors.green : Colors.red;

    // 计算新余额，交易表达式中显示原值
    final newAmount = originalAmount + balanceChange * transactionAmount;
    final displayNewAmount = _getTransactionExpressionAmount(newAmount, selectedAccount!.type);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontFamily:
              Theme.of(context).textTheme.bodyMedium?.fontFamily, // 保证字体一致性
        ),
        children: [
          if (!isEditMode)
            TextSpan(
                text:
                    '余额 ${selectedAccount!.currencySymbol}${displayAmount.toStringAsFixed(2)} '),
          TextSpan(
            text: '$operator ${transactionAmount.abs().toStringAsFixed(2)}',
            style: TextStyle(color: changeColor),
          ),
          if (!isEditMode) TextSpan(text: ' = ${displayNewAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  /// 获取交易表达式中的金额显示
  /// 收入和负债账户显示绝对值，其他账户按原值显示
  double _getTransactionExpressionAmount(double amount, AccountType accountType) {
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
