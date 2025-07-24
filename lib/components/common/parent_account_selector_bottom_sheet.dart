import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/state/account/account_repository.dart';

class ParentAccountSelectorBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final AccountSelectorType accountType;
  final Account? selectedAccount;

  const ParentAccountSelectorBottomSheet({
    super.key,
    required this.title,
    required this.accountType,
    this.selectedAccount,
  });

  static Future<Account?> show(
    BuildContext context, {
    required String title,
    required AccountSelectorType accountType,
    Account? selectedAccount,
  }) {
    return showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (context) => ParentAccountSelectorBottomSheet(
        title: title,
        accountType: accountType,
        selectedAccount: selectedAccount,
      ),
    );
  }

  @override
  ConsumerState<ParentAccountSelectorBottomSheet> createState() =>
      _ParentAccountSelectorBottomSheetState();
}

class _ParentAccountSelectorBottomSheetState
    extends ConsumerState<ParentAccountSelectorBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final accountsAsync = _getAccountProvider(widget.accountType);

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),

          // 分割线
          Divider(
            height: 1,
            color: Colors.grey[200],
          ),

          // Account list
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(
                    child: Text('暂无账户数据'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildAccountList(accounts),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('加载失败: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根据账户类型选择对应的provider
  AsyncValue<List<Account>> _getAccountProvider(
      AccountSelectorType accountType) {
    switch (accountType) {
      case AccountSelectorType.asset:
        return ref.watch(assetsAccountTreeProvider);
      case AccountSelectorType.liability:
        return ref.watch(liabilityAccountTreeProvider);
      case AccountSelectorType.expense:
        return ref.watch(expenseAccountTreeProvider);
      case AccountSelectorType.income:
        return ref.watch(incomeAccountTreeProvider);
      case AccountSelectorType.equity:
        return ref.watch(equityAccountTreeProvider);
    }
  }

  List<Widget> _buildAccountList(List<Account> accounts) {
    return accounts.map((account) {
      return _ParentAccountItem(
        account: account,
        selectedAccount: widget.selectedAccount,
        onTap: (selectedAccount) {
          Navigator.of(context).pop(selectedAccount);
        },
        isRootLevel: true, // 标记为根级别账户
      );
    }).toList();
  }
}

class _ParentAccountItem extends StatefulWidget {
  final Account account;
  final Account? selectedAccount;
  final void Function(Account account) onTap;
  final bool isRootLevel; // 是否为根级别账户

  const _ParentAccountItem({
    required this.account,
    this.selectedAccount,
    required this.onTap,
    this.isRootLevel = false,
  });

  @override
  State<_ParentAccountItem> createState() => _ParentAccountItemState();
}

class _ParentAccountItemState extends State<_ParentAccountItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool hasChildren =
        widget.account.children != null && widget.account.children!.isNotEmpty;
    final bool isSelected = widget.selectedAccount?.id == widget.account.id;
    
    // 判断是否可以选择：只允许选择一级账户（根级别账户）
    final bool canSelect = widget.isRootLevel;

    if (hasChildren) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            title: InkWell(
              onTap: canSelect ? () => widget.onTap(widget.account) : null,
              child: _AccountRow(
                account: widget.account,
                isSelected: isSelected,
                isDisabled: !canSelect,
              ),
            ),
            children: widget.account.children!.map<Widget>((childAccount) {
              return Container(
                margin: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 4.0, top: 0),
                child: _ParentAccountItem(
                  account: childAccount,
                  selectedAccount: widget.selectedAccount,
                  onTap: widget.onTap,
                  isRootLevel: false, // 子账户不是根级别
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else {
      // 叶子节点
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: InkWell(
          onTap: canSelect ? () => widget.onTap(widget.account) : null,
          borderRadius: BorderRadius.circular(8.0),
          child: _AccountRow(
            account: widget.account,
            isSelected: isSelected,
            isDisabled: !canSelect,
          ),
        ),
      );
    }
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final bool isDisabled;

  const _AccountRow({
    required this.account,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle nameStyle = TextStyle(
      fontSize: 15.0,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      color: isDisabled 
          ? Colors.grey[400]
          : (isSelected ? Colors.blue[700] : Colors.black87),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          if (account.icon != null) ...[
            Icon(
              account.icon,
              size: 24,
              color: isDisabled 
                  ? Colors.grey[300]
                  : (isSelected ? Colors.blue[700] : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              account.name,
              style: nameStyle,
            ),
          ),
          if (account.amount != 0) ...[
            Text(
              '${account.currencySymbol}${account.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14.0,
                color: isDisabled 
                    ? Colors.grey[300]
                    : (isSelected ? Colors.blue[600] : Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
