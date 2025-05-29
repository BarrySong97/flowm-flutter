import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowm/components/account/account_row.dart'; // Import the new AccountRow

// Data model for an account
class Account {
  final int id;
  final String name;
  final double amount;
  final IconData?
      icon; // Icon for the account (e.g., for child items like "保险")
  final List<Account>? children; // Sub-accounts
  final String currencySymbol; // e.g., "¥", "$", ""
  final double? percentage; // Percentage of this account among its siblings

  Account({
    required this.id,
    required this.name,
    required this.amount,
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
    Key? key,
    required this.account,
    this.onTap, // 可选的onTap参数
  }) : super(key: key);

  @override
  _AccountItemState createState() => _AccountItemState();
}

class _AccountItemState extends State<AccountItem> {
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
          icon: child.icon,
          children:
              child.children, // Children of children are not processed here
          currencySymbol: child.currencySymbol,
          percentage: childPercentage,
        );
      }).toList();
    }

    // Parent row: show currency symbol only if it has NO children.
    // If it HAS children, its amount is a sum, so don't show symbol.
    Widget accountRowWidget = AccountRow(
      account: widget.account,
      percentage: widget.account.percentage,
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
            key: PageStorageKey<Account>(
                widget.account), // Preserve expansion state
            title: GestureDetector(
              onDoubleTap: widget.onTap != null
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
//     name: '投资理财',
//     amount: 0.00,
//     currencySymbol: '¥', // Base currency, though not shown for parent itself
//     children: [
//       Account(
//         name: '保险',
//         amount: 0.00,
//         icon: Icons.shield,
//         currencySymbol: '¥'
//       ),
//       Account(
//         name: '基金',
//         amount: 1500.75,
//         icon: Icons.trending_up,
//         currencySymbol: '¥'
//       ),
//       Account(
//         name: '零钱通', // Child without icon
//         amount: 200.50,
//         currencySymbol: '¥'
//       )
//     ],
//   );
//
//   final Account singleSavingsAccount = Account(
//     name: '活期存款',
//     amount: 10250.55,
//     icon: Icons.account_balance,
//     currencySymbol: '¥'
//   );
//
//   final Account simpleDebtAccount = Account(
//     name: '信用卡账单',
//     amount: -500.00,
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
//               name: '股票账户',
//               amount: 12345.67,
//               children: [], // Has the potential for children
//               currencySymbol: '¥'
//             )
//           ),
//           // Example of a very simple single item
//            AccountItem(
//             account: Account(
//               name: '现金',
//               amount: 300.00,
//               currencySymbol: '¥'
//             )
//           ),
//         ],
//       ),
//     );
//   }
// }

*/
