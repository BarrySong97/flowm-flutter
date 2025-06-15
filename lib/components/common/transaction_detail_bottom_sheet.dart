import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/transaction_type_map.dart';
import '../../db/tables/account_table.dart';
import '../../pages/add_page.dart';

class TransactionDetailBottomSheet extends StatelessWidget {
  final String amount;
  final String subtitle; // 包含 "fromAccount -> toAccount" 格式的字符串
  final String date;
  final bool isExpense;
  final String? transactionId;
  final String? description;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;
  final double? transactionAmount; // 原始交易金额数值
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const TransactionDetailBottomSheet({
    super.key,
    required this.amount,
    required this.subtitle,
    required this.date,
    this.isExpense = true,
    this.transactionId,
    this.description,
    this.fromAccountType,
    this.toAccountType,
    this.transactionAmount,
    this.onEdit,
    this.onCopy,
    this.onShare,
    this.onDelete,
  });

  static void show({
    required BuildContext context,
    required String amount,
    required String subtitle,
    required String date,
    bool isExpense = true,
    String? transactionId,
    String? description,
    AccountType? fromAccountType,
    AccountType? toAccountType,
    double? transactionAmount,
    VoidCallback? onEdit,
    VoidCallback? onCopy,
    VoidCallback? onShare,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailBottomSheet(
        amount: amount,
        subtitle: subtitle,
        date: date,
        isExpense: isExpense,
        transactionId: transactionId,
        description: description,
        fromAccountType: fromAccountType,
        toAccountType: toAccountType,
        transactionAmount: transactionAmount,
        onEdit: onEdit,
        onCopy: onCopy,
        onShare: onShare,
        onDelete: onDelete,
      ),
    );
  }

  // 解析 subtitle 获取账户名称
  Map<String, String> _parseAccountNames() {
    if (subtitle.contains(' -> ')) {
      final parts = subtitle.split(' -> ');
      return {
        'fromAccount': parts[0].trim(),
        'toAccount': parts[1].trim(),
      };
    }
    return {
      'fromAccount': '未知账户',
      'toAccount': '未知账户',
    };
  }

  // 计算账户金额变化
  String _getAccountAmountChange(bool isFromAccount) {
    double amountValue = transactionAmount ?? 0.0;

    // 如果没有传入 transactionAmount，尝试从 amount 字符串中解析
    if (amountValue == 0.0) {
      final numericAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      amountValue = double.tryParse(numericAmount) ?? 0.0;
    }

    if (isFromAccount) {
      // 转出账户显示负数
      return '-¥${amountValue.toStringAsFixed(2)}';
    } else {
      // 转入账户显示正数
      return '+¥${amountValue.toStringAsFixed(2)}';
    }
  }

  void _handleCopy(BuildContext context) {
    final accountNames = _parseAccountNames();
    final details = '''
转账金额: $amount
转出账户: ${accountNames['fromAccount']}
转入账户: ${accountNames['toAccount']}
记账日期: $date
${description != null ? '备注: $description' : ''}
${transactionId != null ? '交易ID: $transactionId' : ''}
''';

    Clipboard.setData(ClipboardData(text: details));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('交易详情已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );

    onCopy?.call();
  }

  void _handleDelete(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('确认删除'),
        content: const Text('您确定要删除这笔交易吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountNames = _parseAccountNames();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 主要内容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 金额显示
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: isExpense
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF34C759),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 账户详情列表
                  _buildAccountDetailItem(
                    accountName: accountNames['fromAccount']!,
                    amountChange: _getAccountAmountChange(true),
                    isFromAccount: true,
                  ),
                  _buildAccountDetailItem(
                    accountName: accountNames['toAccount']!,
                    amountChange: _getAccountAmountChange(false),
                    isFromAccount: false,
                  ),
                  _buildDetailItem(
                    label: '记账日期',
                    value: date,
                  ),

                  const SizedBox(height: 40),

                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: '编辑',
                        color: const Color(0xFF007AFF),
                        onTap: () {
                          Navigator.pop(context);
                          if (transactionId != null) {
                            final id = int.tryParse(transactionId!);
                            if (id != null) {
                              context.push('/add', extra: id);
                            }
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: '删除',
                        color: const Color(0xFFFF3B30),
                        onTap: () => _handleDelete(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailItem({
    required String accountName,
    required String amountChange,
    required bool isFromAccount,
  }) {
    final isPositive = amountChange.startsWith('+');
    final isNegative = amountChange.startsWith('-');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFromAccount ? '转出账户' : '转入账户',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accountName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountChange,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? const Color(0xFF34C759)
                  : isNegative
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
