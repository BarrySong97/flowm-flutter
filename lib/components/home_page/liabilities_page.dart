import 'package:flutter/material.dart';
import 'package:flowm/components/chart/area_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model

class LiabilitiesPage extends StatelessWidget {
  const LiabilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Account investmentAccount = Account(
      name: '投资理财',
      amount: 5200.75,
      currencySymbol: '¥',
      children: [
        Account(
            name: '保险',
            amount: 1000.00,
            icon: Icons.shield,
            currencySymbol: '¥'),
        Account(
            name: '基金',
            amount: 3500.75,
            icon: Icons.trending_up,
            currencySymbol: '¥'),
        Account(name: '零钱通', amount: 700.00, currencySymbol: '¥'),
      ],
    );

    final Account savingsAccount = Account(
      name: '活期存款',
      amount: 10250.55,
      icon: Icons.account_balance_wallet,
      currencySymbol: '¥',
    );

    final Account cashAccount = Account(
      name: '现金',
      amount: 300.00,
      currencySymbol: '¥',
    );

    final Account stockAccount = Account(
      name: '股票账户',
      amount: 12345.67,
      children: [], // Potential parent, but no children currently
      currencySymbol: '¥',
    );

    final List<Account> accounts = [
      investmentAccount,
      savingsAccount,
      stockAccount,
      cashAccount,
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 12,
          children: [
            Container(
              padding: EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '总资产',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '2000',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AreaChartWidget()
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '资产分布',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.hardEdge,
              child: const Text('Social Media Usage Demo'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // To use within SingleChildScrollView
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                return AccountItem(account: accounts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
