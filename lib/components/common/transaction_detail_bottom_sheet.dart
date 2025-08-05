import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../db/tables/account_table.dart';
import '../../state/transaction/transaction_repository.dart';
import '../../state/ledger/ledger_repository.dart';
import 'package:flowm/utils/snackbar_utils.dart';
import '../../utils/transaction_type_map.dart';
import '../../utils/account_transaction_validator.dart';
import '../../config/app_constants.dart';

class TransactionDetailBottomSheet extends ConsumerWidget {
  final String amount;
  final String subtitle; // 包含 "fromAccount -> toAccount" 格式的字符串
  final String date;
  final bool isExpense;
  final String? transactionId;
  final String? description;
  final AccountType? fromAccountType;
  final AccountType? toAccountType;
  final double? transactionAmount; // 原始交易金额数值
  final DateTime? transactionDate; // 完整的交易日期时间
  final DateTime? createDate; // 记录创建时间
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
    this.transactionDate,
    this.createDate,
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
    DateTime? transactionDate,
    DateTime? createDate,
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
        transactionDate: transactionDate,
        createDate: createDate,
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
      // 移除时间部分（如果存在）
      String toAccount = parts[1].trim();
      if (toAccount.contains(' · ')) {
        toAccount = toAccount.split(' · ')[0].trim();
      }
      return {
        'fromAccount': parts[0].trim(),
        'toAccount': toAccount,
      };
    }
    return {
      'fromAccount': '未知账户',
      'toAccount': '未知账户',
    };
  }

  // 计算账户金额变化
  String _getAccountAmountChange(bool isFromAccount, {String currencySymbol = AppConstants.currencySymbol}) {
    double amountValue = transactionAmount ?? 0.0;

    // 如果没有传入 transactionAmount，尝试从 amount 字符串中解析
    if (amountValue == 0.0) {
      final numericAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      amountValue = double.tryParse(numericAmount) ?? 0.0;
    }

    // 使用与 add_page.dart 相同的逻辑来决定符号
    if (fromAccountType != null && toAccountType != null) {
      final symbol = AccountTransactionValidator.getAccountSymbol(
        accountType: isFromAccount ? fromAccountType! : toAccountType!,
        isFromAccount: isFromAccount,
        counterpartAccountType: isFromAccount ? toAccountType : fromAccountType,
      );
      
      return '$symbol$currencySymbol${amountValue.toStringAsFixed(2)}';
    }

    // 退回到简单逻辑作为默认值
    if (isFromAccount) {
      return '-$currencySymbol${amountValue.toStringAsFixed(2)}';
    } else {
      return '+$currencySymbol${amountValue.toStringAsFixed(2)}';
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) async {
    if (transactionId == null) {
      Navigator.pop(context);
      if (context.mounted) {
        SnackBarUtils.showOverlayError(context, '无法删除：交易ID为空');
      }
      return;
    }

    // 在widget销毁前获取repository引用
    final transactionRepository = ref.read(transactionRepositoryProvider);

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
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
            onPressed: () async {
              Navigator.pop(context);

              try {
                final id = int.parse(transactionId!);
                await transactionRepository.deleteTransactionWithPostings(id);

                if (context.mounted) {
                  SnackBarUtils.showOverlaySuccess(context, '交易删除成功');
                }

                // 调用回调函数通知父组件
                onDelete?.call();
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showOverlayError(context, '删除失败: $e');
                }
              }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLedger = ref.watch(selectedLedgerProvider).value;
    final accountNames = _parseAccountNames();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7CC),
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            // 主要内容
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  // 金额显示区域
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: isExpense
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF34C759),
                            height: 1.1,
                          ),
                        ),
                        if (description != null && description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              description!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 交易类型显示
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getTransactionTypeColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTransactionTypeIcon(),
                          color: _getTransactionTypeColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTransactionTypeText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getTransactionTypeColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 交易详情卡片
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildAccountDetailItem(
                          accountName: accountNames['fromAccount']!,
                          amountChange: _getAccountAmountChange(true, currencySymbol: selectedLedger?.currencySymbol ?? '¥'),
                          isFromAccount: true,
                        ),
                        const Divider(
                          height: 24,
                          color: Color(0xFFF0F0F0),
                          thickness: 1,
                        ),
                        _buildAccountDetailItem(
                          accountName: accountNames['toAccount']!,
                          amountChange: _getAccountAmountChange(false, currencySymbol: selectedLedger?.currencySymbol ?? '¥'),
                          isFromAccount: false,
                        ),
                        const Divider(
                          height: 24,
                          color: Color(0xFFF0F0F0),
                          thickness: 1,
                        ),
                        _buildDetailItem(
                          label: '交易时间',
                          value: _getFormattedTransactionDateTime(),
                          icon: Icons.schedule_rounded,
                        ),
                        const Divider(
                          height: 24,
                          color: Color(0xFFF0F0F0),
                          thickness: 1,
                        ),
                        _buildDetailItem(
                          label: '记录时间',
                          value: _getFormattedCreateDateTime(),
                          icon: Icons.history_rounded,
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.edit_rounded,
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete_rounded,
                          label: '删除',
                          color: const Color(0xFFFF3B30),
                          onTap: () => _handleDelete(context, ref),
                        ),
                      ),
                    ],
                  ),
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

    return Row(
      children: [
        // 账户图标
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isFromAccount 
                ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                : const Color(0xFF34C759).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isFromAccount ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isFromAccount 
                ? const Color(0xFFFF3B30)
                : const Color(0xFF34C759),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        
        // 账户信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFromAccount ? '转出账户' : '转入账户',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                accountName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // 金额变化
        Text(
          amountChange,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _getAmountChangeColor(amountChange),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon ?? Icons.calendar_today_rounded,
            color: Color(0xFF007AFF),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? const Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 获取交易类型文本
  String _getTransactionTypeText() {
    if (fromAccountType != null && toAccountType != null) {
      return getTransactionFlowType(fromAccountType!, toAccountType!);
    }
    return '未知类型';
  }

  // 获取交易类型颜色
  Color _getTransactionTypeColor() {
    if (fromAccountType != null && toAccountType != null) {
      final nature = getTransactionNature(fromAccountType, toAccountType);
      switch (nature) {
        case TransactionNature.INFLOW:
          return const Color(0xFF34C759);
        case TransactionNature.OUTFLOW:
          return const Color(0xFFFF3B30);
        case TransactionNature.TRANSFER:
          return const Color(0xFF007AFF);
        default:
          return const Color(0xFF8E8E93);
      }
    }
    return const Color(0xFF8E8E93);
  }

  // 获取交易类型图标
  IconData _getTransactionTypeIcon() {
    if (fromAccountType != null && toAccountType != null) {
      final nature = getTransactionNature(fromAccountType, toAccountType);
      switch (nature) {
        case TransactionNature.INFLOW:
          return Icons.arrow_downward_rounded;
        case TransactionNature.OUTFLOW:
          return Icons.arrow_upward_rounded;
        case TransactionNature.TRANSFER:
          return Icons.swap_horiz_rounded;
        default:
          return Icons.help_outline_rounded;
      }
    }
    return Icons.help_outline_rounded;
  }

  // 获取金额变化的颜色
  Color _getAmountChangeColor(String amountChange) {
    if (amountChange.startsWith('+')) {
      return const Color(0xFF34C759);
    } else if (amountChange.startsWith('-')) {
      return const Color(0xFFFF3B30);
    } else {
      return const Color(0xFF1C1C1E);
    }
  }

  // 获取格式化的交易日期时间
  String _getFormattedTransactionDateTime() {
    if (transactionDate != null) {
      final dateFormatter = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');
      final timeFormatter = DateFormat('HH:mm');
      final formattedDate = dateFormatter.format(transactionDate!);
      final formattedTime = timeFormatter.format(transactionDate!);
      
      if (formattedTime == '00:00') {
        return formattedDate;
      } else {
        return '$formattedDate · $formattedTime';
      }
    }
    return date;
  }

  // 获取格式化的记录创建时间
  String _getFormattedCreateDateTime() {
    if (createDate != null) {
      final dateFormatter = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');
      final timeFormatter = DateFormat('HH:mm');
      final formattedDate = dateFormatter.format(createDate!);
      final formattedTime = timeFormatter.format(createDate!);
      
      if (formattedTime == '00:00') {
        return formattedDate;
      } else {
        return '$formattedDate · $formattedTime';
      }
    }
    // 如果没有创建时间，显示当前时间作为后备
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');
    final timeFormatter = DateFormat('HH:mm');
    return '${dateFormatter.format(now)} · ${timeFormatter.format(now)}';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
