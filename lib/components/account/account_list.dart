import 'package:flutter/material.dart';
import 'package:flowm/components/account/account_item.dart'; // Assuming Account and AccountItem are in this file

class AccountList extends StatelessWidget {
  final List<Account> accounts;

  const AccountList({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Center(
        child: Text('No accounts to display.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Important if inside a Column or another scrollable
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling if parent handles it
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        return AccountItem(account: accounts[index]);
      },
    );
  }
}
