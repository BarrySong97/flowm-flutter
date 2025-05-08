import 'package:flutter/material.dart';
import 'package:flowm/components/account/styled_account_item.dart';

class StyledAccountList extends StatelessWidget {
  final List<StyledAccount> accounts;

  const StyledAccountList({
    Key? key,
    required this.accounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No accounts to display.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0), // Add horizontal padding here for the whole list
      itemBuilder: (context, index) {
        return StyledAccountItem(account: accounts[index]);
      },
    );
  }
}
