import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../chart/custom_pie_chart.dart';
import '../../account/styled_account_item.dart';
import '../../account/styled_account_list.dart';
import '../../../config/app_constants.dart';
import '../../../state/icome/income_providers.dart';

/// 收入饼图和账户列表组件
class IncomePieChartSection extends StatelessWidget {
  final IncomePageData data;

  const IncomePieChartSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.accountTree.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.largeSpacing),
            child: Text('当月无收入分类数据'),
          ),
        ),
      );
    }

    final pieChartIncomeData = data.accountTree
        .asMap()
        .entries
        .map((entry) => {
              'category': entry.value.accountData.accountName,
              'amount': entry.value.balance,
              'color': AppConstants
                  .incomeColors[entry.key % AppConstants.incomeColors.length],
            })
        .toList();

    final styledAccounts = data.accountTree
        .asMap()
        .entries
        .map((entry) => StyledAccount(
              name: entry.value.accountData.accountName,
              rawAmount: entry.value.balance,
              currencySymbol: AppConstants.currencySymbol,
              iconData: Icons.label_outline,
              leadingColor: AppConstants
                  .incomeColors[entry.key % AppConstants.incomeColors.length],
              percentageText: '${entry.value.percentage.toStringAsFixed(0)}%',
            ))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        children: [
          SizedBox(
            height: AppConstants.pieChartHeight,
            child: CustomPieChart(expenseData: pieChartIncomeData),
          ),
          StyledAccountList(
            accounts: styledAccounts,
            onItemTap: (index) {
              final selectedNode = data.accountTree[index];
              if (selectedNode.children.isNotEmpty) {
                GoRouter.of(context).pushNamed(
                  'topIncomeDetail',
                  extra: {'account': selectedNode},
                );
              } else {
                GoRouter.of(context).pushNamed(
                  'incomeDetail',
                  extra: {'account': selectedNode},
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
