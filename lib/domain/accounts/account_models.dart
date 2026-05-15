import 'package:flowm/db/app_database.dart' show Account;
import 'package:flowm/db/tables/account_table.dart' show AccountType;

enum AccountTreeType { asset, liability, expense, income, equity }

extension AccountTreeTypeAccountType on AccountTreeType {
  AccountType get accountType {
    switch (this) {
      case AccountTreeType.asset:
        return AccountType.ASSET;
      case AccountTreeType.liability:
        return AccountType.LIABILITY;
      case AccountTreeType.expense:
        return AccountType.EXPENSE;
      case AccountTreeType.income:
        return AccountType.INCOME;
      case AccountTreeType.equity:
        return AccountType.EQUITY;
    }
  }
}

class AccountTreeNode {
  const AccountTreeNode({
    required this.account,
    required this.balance,
    this.percentage = 0,
    this.children = const [],
  });

  final Account account;
  final double balance;
  final double percentage;
  final List<AccountTreeNode> children;

  AccountTreeNode copyWith({
    Account? account,
    double? balance,
    double? percentage,
    List<AccountTreeNode>? children,
  }) {
    return AccountTreeNode(
      account: account ?? this.account,
      balance: balance ?? this.balance,
      percentage: percentage ?? this.percentage,
      children: children ?? this.children,
    );
  }
}

class RawAccountTreeNode {
  const RawAccountTreeNode({
    required this.account,
    this.children = const [],
  });

  final Account account;
  final List<RawAccountTreeNode> children;
}

class BalancePoint {
  const BalancePoint({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final double amount;
}
