import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart';

class AccountSelectorItem extends StatefulWidget {
  final Account account;
  final void Function(Account account)? onTap;
  final bool isSelected;
  final bool shouldAutoExpand;
  final Account? selectedAccount;

  const AccountSelectorItem({
    Key? key,
    required this.account,
    this.onTap,
    this.isSelected = false,
    this.shouldAutoExpand = false,
    this.selectedAccount,
  }) : super(key: key);

  @override
  _AccountSelectorItemState createState() => _AccountSelectorItemState();
}

class _AccountSelectorItemState extends State<AccountSelectorItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.shouldAutoExpand;
  }

  @override
  void didUpdateWidget(AccountSelectorItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAutoExpand != oldWidget.shouldAutoExpand) {
      setState(() {
        _isExpanded = widget.shouldAutoExpand;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasChildren =
        widget.account.children != null && widget.account.children!.isNotEmpty;

    // Calculate percentages for children if they exist
    List<Account>? childrenWithPercentage;
    if (hasChildren) {
      double totalChildrenAmount = widget.account.children!.fold(
          0.0,
          (sum, item) =>
              sum +
              item.amount.abs()); // Use absolute amount for total calculation
      childrenWithPercentage = widget.account.children!.map((child) {
        double childPercentage = totalChildrenAmount == 0
            ? 0.0
            : (child.amount.abs() / totalChildrenAmount) * 100;
        return Account(
          id: child.id,
          name: child.name,
          amount: child.amount,
          type: child.type,
          icon: child.icon,
          children:
              child.children, // Children of children are not processed here
          currencySymbol: child.currencySymbol,
          percentage: childPercentage,
        );
      }).toList();
    }

    // Parent row: show currency symbol only if it has NO children.
    Widget accountRowWidget = _AccountSelectorRow(
      account: widget.account,
      percentage: widget.account.percentage,
      showCurrencySymbolInAmount: !hasChildren,
      isSelected: hasChildren ? false : widget.isSelected, // 有子账户的父账户永远不显示为选中状态
      isLeafNode: !hasChildren, // 传入是否为叶子节点
    );

    if (hasChildren) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white, // 父账户容器背景色始终为白色
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[200]!, width: 1), // 父账户边框始终为灰色
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<Account>(widget.account),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            title: accountRowWidget,
            children: childrenWithPercentage!.map<Widget>((childAccount) {
              // 检查子账户是否被选中
              final bool isChildSelected = widget.selectedAccount != null &&
                  widget.selectedAccount!.id == childAccount.id;

              // 检查子账户是否也有子账户（多级嵌套）
              final bool childHasChildren = childAccount.children != null &&
                  childAccount.children!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 4.0, top: 0),
                decoration: BoxDecoration(
                  color: isChildSelected && !childHasChildren
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.0),
                  border: isChildSelected && !childHasChildren
                      ? Border.all(color: Colors.blue, width: 1)
                      : null,
                ),
                child: InkWell(
                  onTap: !childHasChildren && widget.onTap != null
                      ? () => widget.onTap!(childAccount)
                      : null, // 只有叶子节点才能被点击
                  borderRadius: BorderRadius.circular(6.0),
                  child: _AccountSelectorRow(
                    account: childAccount,
                    percentage: childAccount.percentage,
                    showCurrencySymbolInAmount: true,
                    isSelected:
                        isChildSelected && !childHasChildren, // 只有叶子节点才能显示选中状态
                    isLeafNode: !childHasChildren, // 传入是否为叶子节点
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else {
      // For accounts without children, just display the row
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color:
              widget.isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: widget.isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: InkWell(
          onTap:
              widget.onTap != null ? () => widget.onTap!(widget.account) : null,
          borderRadius: BorderRadius.circular(8.0),
          child: _AccountSelectorRow(
            account: widget.account,
            percentage: widget.account.percentage,
            showCurrencySymbolInAmount: true,
            isSelected: widget.isSelected,
            isLeafNode: true, // 叶子节点
          ),
        ),
      );
    }
  }
}

class _AccountSelectorRow extends StatelessWidget {
  final Account account;
  final double? percentage;
  final bool showCurrencySymbolInAmount;
  final bool isSelected;
  final bool isLeafNode;

  const _AccountSelectorRow({
    Key? key,
    required this.account,
    this.percentage,
    required this.showCurrencySymbolInAmount,
    this.isSelected = false,
    this.isLeafNode = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = 15.0;
    final TextStyle nameStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      color: isSelected
          ? Colors.blue[700]
          : (isLeafNode ? Colors.black87 : Colors.grey[600]),
    );
    final TextStyle amountStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: isSelected
          ? Colors.blue[700]
          : (isLeafNode ? Colors.black87 : Colors.grey[600]),
    );
    final TextStyle balanceStyle = TextStyle(
      fontSize: fontSize - 2,
      fontWeight: FontWeight.normal,
      color: isSelected ? Colors.blue[600] : Colors.grey[600],
    );

    String displayedAmount;
    if (showCurrencySymbolInAmount) {
      displayedAmount =
          '${account.currencySymbol}${account.amount.toStringAsFixed(2)}';
    } else {
      displayedAmount = account.amount.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 16.0), // 统一在这里添加padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (account.icon != null) ...[
                  Icon(
                    account.icon,
                    color: isSelected
                        ? Colors.blue
                        : (isLeafNode ? Colors.blueAccent : Colors.grey[400]),
                    size: 22,
                  ),
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
                      if (!isLeafNode)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(分类)',
                            style: TextStyle(
                              fontSize: fontSize - 3,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (percentage != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(${percentage!.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: isSelected
                                  ? Colors.blue[500]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('余额', style: balanceStyle),
              const SizedBox(height: 2),
              Text(displayedAmount, style: amountStyle),
            ],
          ),
        ],
      ),
    );
  }
}
