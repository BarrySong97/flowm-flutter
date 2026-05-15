import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart' as account_ui;
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/domain/accounts/account_models.dart';

class AccountPresentationMapper {
  const AccountPresentationMapper();

  List<account_ui.Account> toUiAccounts(
    List<AccountTreeNode> nodes, {
    String currencySymbol = '¥',
  }) {
    return nodes
        .map((node) => account_ui.Account(
              id: node.account.accountId,
              name: node.account.accountName,
              type: node.account.accountType,
              amount: node.balance,
              icon: _iconFor(node.account.accountType),
              children: toUiAccounts(
                node.children,
                currencySymbol: currencySymbol,
              ),
              currencySymbol: currencySymbol,
            ))
        .toList();
  }

  IconData _iconFor(AccountType accountType) {
    switch (accountType) {
      case AccountType.ASSET:
        return Icons.account_balance_wallet;
      case AccountType.LIABILITY:
        return Icons.credit_card;
      case AccountType.EXPENSE:
        return Icons.trending_down;
      case AccountType.INCOME:
        return Icons.trending_up;
      case AccountType.EQUITY:
        return Icons.pie_chart;
    }
  }
}
