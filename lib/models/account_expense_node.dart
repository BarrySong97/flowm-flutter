import '../db/app_database.dart'; // For Account data class

class AccountExpenseNode {
  final Account accountData;
  double balance; // 余额，会被递归更新
  double percentage; // 占比，后续计算
  List<AccountExpenseNode> children; // 子节点

  AccountExpenseNode({
    required this.accountData,
    required this.balance, // 初始化为直接余额
    this.percentage = 0.0,
    List<AccountExpenseNode>? children,
  }) : children = children ?? [];

  /// 便于调试或API返回的toJson方法
  Map<String, dynamic> toJson() {
    return {
      'account': {
        'id': accountData.accountId,
        'name': accountData.accountName,
        'account_type': accountData.accountType.name,
        'parent_account_id': accountData.parentAccountId,
        'full_path': accountData.fullPath,
        'is_active': accountData.isActive,
      },
      'balance': balance,
      'percentage': percentage,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}
