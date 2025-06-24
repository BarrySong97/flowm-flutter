import 'package:flowm/db/tables/account_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/pages/expense/expense_detail_page.dart'
    as detail_page_providers;
import 'package:flowm/pages/income/income_detail_page.dart'
    as income_detail_page_providers;
import 'package:flowm/state/expense/expense_repository.dart'
    as expense_repository;
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:flowm/state/home_page/overview_page_providers.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/state/liabilities/liabilities_repository.dart'
    as liabilities;

/// 根据交易中涉及的账户类型，有选择地使 providers 失效。
///
/// 这通常在创建、更新或删除交易后调用，以确保UI反映最新状态。
void invalidateProvidersForTransaction(
  WidgetRef ref, {
  required AccountType fromAccountType,
  required AccountType toAccountType,
}) {
  final types = {fromAccountType, toAccountType};
  print(2);
  // 总是刷新通用 providers
  ref.invalidate(monthlyOverviewDataProvider);
  ref.invalidate(latestTransactionsProvider);

  // 根据账户类型刷新特定 providers
  if (types.contains(AccountType.ASSET)) {
    ref.invalidate(assetsPageDataProvider);
    ref.invalidate(topAssetAccountsProvider);
    ref.invalidate(assetsAccountTreeProvider);
    ref.invalidate(assetSubAccountTreeProvider);
    ref.invalidate(assetTrendProviderByDateRange);
    ref.invalidate(assetTrendProviderByTimeRange);
    ref.invalidate(accountTransactionsProvider);
    ref.invalidate(assetsSankeyChartDataProvider);
  }

  if (types.contains(AccountType.LIABILITY)) {
    ref.invalidate(totalLiabilitiesProvider);
    ref.invalidate(liabilities.uiLiabilityAccountsProvider);
    ref.invalidate(liabilities.topLiabilityAccountsProvider);
    ref.invalidate(liabilities.liabilityTrendProviderByDateRange);
    ref.invalidate(liabilityAccountTreeProvider);
    ref.invalidate(liabilities.liabilityTrendProviderByTimeRange);
    ref.invalidate(liabilitySubAccountTreeProvider);
    ref.invalidate(liabilities.sankeyChartDataProvider);
  }

  if (types.contains(AccountType.EXPENSE)) {
    ref.invalidate(expensePageDataProvider);
    ref.invalidate(expenseAccountTreeProvider);
    ref.invalidate(expenseChartDataProvider);
    ref.invalidate(detail_page_providers.expenseChartDataProvider);
    ref.invalidate(previousMonthExpenseProviderFamily);
    ref.invalidate(accountMonthlyExpenseProvider);
    ref.invalidate(detail_page_providers.accountMonthlyExpenseProvider);
    ref.invalidate(accountOverallExpenseProvider);
    ref.invalidate(detail_page_providers.accountOverallExpenseProvider);
  }

  if (types.contains(AccountType.INCOME)) {
    ref.invalidate(incomePageDataProvider);
    ref.invalidate(incomeAccountTreeProvider);
    ref.invalidate(incomeChartDataProviderFamily);
    ref.invalidate(income_detail_page_providers.incomeChartDataProvider);
    ref.invalidate(previousMonthIncomeProviderFamily);
    ref.invalidate(accountMonthlyIncomeProvider);
    ref.invalidate(income_detail_page_providers.accountMonthlyIncomeProvider);
    ref.invalidate(accountOverallIncomeProvider);
    ref.invalidate(income_detail_page_providers.accountOverallIncomeProvider);
  }

  if (types.contains(AccountType.EQUITY)) {
    ref.invalidate(equityAccountTreeProvider);
  }
}
