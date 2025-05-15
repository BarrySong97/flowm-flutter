import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Data model for an account
class Account {
  final String name;
  final double amount;
  final IconData?
      icon; // Icon for the account (e.g., for child items like "保险")
  final List<Account>? children; // Sub-accounts
  final String currencySymbol; // e.g., "¥", "$", ""
  final double? percentage; // Percentage of this account among its siblings

  Account({
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

  const AccountItem({
    Key? key,
    required this.account,
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

    Widget accountRow = _buildAccountRow(
      context: context,
      account: widget.account,
      isParentRow: true, // Still useful for styling/amount display logic
      percentage: widget.account.percentage,
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
            title: accountRow,
            children: childrenWithPercentage!.map<Widget>((childAccount) {
              return Padding(
                // Add padding for child items if desired
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 4.0, top: 0),
                child: InkWell(
                  onTap: () => _navigateToDetailPage(context, childAccount),
                  child: _buildAccountRow(
                    context: context,
                    account: childAccount,
                    isParentRow: false,
                    percentage: childAccount.percentage,
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
          onTap: () => _navigateToDetailPage(context, widget.account),
          child: Padding(
            // Add padding to match ExpansionTile's content
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: accountRow,
          ),
        ),
      );
    }
  }

  void _navigateToDetailPage(BuildContext context, Account account) {
    context.pushNamed(
      'accountDetail',
      extra: {'account': account},
    );
  }

  Widget _buildAccountRow({
    required BuildContext context,
    required Account account,
    required bool isParentRow,
    double? percentage,
  }) {
    final double fontSize = 15.0;
    final TextStyle nameStyle = TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87);
    final TextStyle amountStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.black87);

    String displayedAmount;
    bool actualHasChildren =
        account.children != null && account.children!.isNotEmpty;

    if (isParentRow && actualHasChildren) {
      // Parent account with children (e.g., "投资理财"): amount without currency symbol
      displayedAmount = account.amount.toStringAsFixed(2);
    } else {
      // Single account or a child account (e.g., "保险"): amount with currency symbol
      displayedAmount =
          '${account.currencySymbol}${account.amount.toStringAsFixed(2)}';
    }

    return Padding(
      // Ensure consistent padding for the row content
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (account.icon != null) ...[
                  Icon(account.icon, color: Colors.blueAccent, size: 22),
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
                      if (percentage != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(displayedAmount, style: amountStyle),
              if (!isParentRow || (isParentRow && !actualHasChildren))
                const SizedBox(width: 24), // Keep space for alignment if needed
            ],
          ),
        ],
      ),
    );
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
