import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_row.dart'; // Import the new AccountRow
import 'package:flowm/db/tables/account_table.dart';

// Data model for an account
class Account {
  final int id;
  final String name;
  final double amount;
  final AccountType type;
  final IconData?
      icon; // Icon for the account (e.g., for child items like "保险")
  final List<Account>? children; // Sub-accounts
  final String currencySymbol; // e.g., "¥", "$", ""
  final double? percentage; // Percentage of this account among its siblings

  Account({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.icon,
    this.children,
    this.currencySymbol = '', // Default to no symbol, explicitly set if needed
    this.percentage,
  });
}

class AccountItem extends StatefulWidget {
  final Account account;
  final void Function(Account account)? onTap; // 添加onTap回调参数

  const AccountItem({
    super.key,
    required this.account,
    this.onTap, // 可选的onTap参数
  });

  @override
  State<AccountItem> createState() => _AccountItemState();
}

class _AccountItemState extends State<AccountItem> {
  late final ExpansibleController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
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
          currencySymbol: widget.account.currencySymbol,
          percentage: childPercentage,
        );
      }).toList();
    }

    // Parent row: show currency symbol only if it has NO children.
    // If it HAS children, its amount is a sum, so don't show symbol.
    Widget accountRowWidget = AccountRow(
      account: widget.account,
      percentage: widget.account.percentage,
      onTap: (account) {
        if (hasChildren) {
          // 有子账户时处理展开/收起
          if (_controller.isExpanded) {
            _controller.collapse();
          } else {
            _controller.expand();
          }
        } else {
          // 叶子节点时调用外部的onTap回调
          if (widget.onTap != null) {
            widget.onTap!(account);
          }
        }
      },
      showCurrencySymbolInAmount: !hasChildren, // Logic for parent row
    );

    if (hasChildren) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        elevation: 0.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            // initiallyExpanded: true,
            controller: _controller,
            key: PageStorageKey<Account>(
                widget.account), // Preserve expansion state
            title: GestureDetector(
              onLongPress: widget.onTap != null
                  ? () => widget.onTap!(widget.account)
                  : null,
              child: accountRowWidget, // Use the new AccountRow widget
            ),
            children: childrenWithPercentage!.map<Widget>((childAccount) {
              return Padding(
                // Add padding for child items if desired
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 4.0, top: 0),
                child: InkWell(
                  // Child row: always show currency symbol.
                  child: AccountRow(
                    account: childAccount,
                    percentage: childAccount.percentage,
                    showCurrencySymbolInAmount:
                        true, // Children always show currency
                    onTap: widget.onTap,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else {
      // For accounts without children, just display the row in a Card
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        elevation: 0.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: InkWell(
          onTap:
              widget.onTap != null ? () => widget.onTap!(widget.account) : null,
          child: Padding(
            // Add padding to match ExpansionTile's content
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: accountRowWidget, // Use the new AccountRow widget
          ),
        ),
      );
    }
  }
}

/*
// Example Usage:
//
// import 'package:flutter/material.dart';
// import 'account_item.dart'; // Assuming this file is in lib/components/account/
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Account Demo',
//       home: MyAccountsPage(),
//     );
//   }
// }
//
// class MyAccountsPage extends StatelessWidget {
//   final Account investmentAccount = Account(
//     id: 1,
//     name: '投资理财',
//     amount: 0.00,
//     type: AccountType.ASSET,
//     currencySymbol: '¥', // Base currency, though not shown for parent itself
//     children: [
//       Account(
//         id: 2,
//         name: '保险',
//         amount: 0.00,
//         type: AccountType.ASSET,
//         icon: Icons.shield,
//         currencySymbol: '¥'
//       ),
//       Account(
//         id: 3,
//         name: '基金',
//         amount: 1500.75,
//         type: AccountType.ASSET,
//         icon: Icons.trending_up,
//         currencySymbol: '¥'
//       ),
//       Account(
//         id: 4,
//         name: '零钱通', // Child without icon
//         amount: 200.50,
//         type: AccountType.ASSET,
//         currencySymbol: '¥'
//       )
//     ],
//   );
//
//   final Account singleSavingsAccount = Account(
//     id: 5,
//     name: '活期存款',
//     amount: 10250.55,
//     type: AccountType.ASSET,
//     icon: Icons.account_balance,
//     currencySymbol: '¥'
//   );
//
//   final Account simpleDebtAccount = Account(
//     id: 6,
//     name: '信用卡账单',
//     amount: -500.00,
//     type: AccountType.LIABILITY,
//     currencySymbol: '¥'
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My Accounts Flowm'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//       ),
//       backgroundColor: Color(0xFFF8F8F8), // A light grey background for the page
//       body: ListView(
//         padding: const EdgeInsets.only(top: 8.0),
//         children: [
//           AccountItem(account: investmentAccount),
//           AccountItem(account: singleSavingsAccount),
//           AccountItem(account: simpleDebtAccount),
//           // Example of a single item that is conceptually a parent but has no children currently
//           AccountItem(
//             account: Account(
//               id: 7,
//               name: '股票账户',
//               amount: 12345.67,
//               type: AccountType.ASSET,
//               children: [], // Has the potential for children
//               currencySymbol: '¥'
//             )
//           ),
//           // Example of a very simple single item
//            AccountItem(
//             account: Account(
//               id: 8,
//               name: '现金',
//               amount: 300.00,
//               type: AccountType.ASSET,
//               currencySymbol: '¥'
//             )
//           ),
//         ],
//       ),
//     );
//   }
// }

*/
