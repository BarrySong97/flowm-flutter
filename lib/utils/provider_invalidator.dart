import 'package:flowm/db/tables/account_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/pages/expense/expense_detail_page.dart'
    as detail_page_providers;
import 'package:flowm/pages/income/income_detail_page.dart'
    as income_detail_page_providers;
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:flowm/state/home_page/overview_page_providers.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/state/liabilities/liabilities_repository.dart'
    as liabilities;
import 'package:flowm/state/transaction/flow_transactions_provider.dart';

typedef ProviderInvalidator = void Function(ProviderOrFamily provider);

/// 根据交易中涉及的账户类型，有选择地使 providers 失效。
///
/// 这通常在创建、更新或删除交易后调用，以确保UI反映最新状态。
/// 也可用于账户删除时刷新相关providers。
void invalidateProvidersForTransaction(
  WidgetRef ref, {
  AccountType? fromAccountType,
  AccountType? toAccountType,
  AccountType? accountType, // 用于账户删除等单一账户类型操作
}) {
  invalidateProvidersForTransactionUsing(
    ref.invalidate,
    fromAccountType: fromAccountType,
    toAccountType: toAccountType,
    accountType: accountType,
  );
}

void invalidateProvidersForTransactionUsing(
  ProviderInvalidator invalidate, {
  AccountType? fromAccountType,
  AccountType? toAccountType,
  AccountType? accountType,
}) {
  final types = <AccountType>{};
  if (fromAccountType != null) types.add(fromAccountType);
  if (toAccountType != null) types.add(toAccountType);
  if (accountType != null) types.add(accountType);

  // 总是刷新通用 providers
  invalidate(monthlyOverviewDataProvider);
  invalidate(latestTransactionsProvider);
  invalidate(flowTransactionsProvider);

  // 失效新的动态账户信息 providers - 这些是核心的账户数据提供者
  invalidate(accountInfoProvider);
  invalidate(accountExpenseNodeProvider);
  invalidate(accountTreeInfoProvider);

  // 根据账户类型刷新特定 providers
  if (types.contains(AccountType.ASSET)) {
    invalidate(assetsPageDataProvider);
    invalidate(topAssetAccountsProvider);
    invalidate(assetsAccountTreeProvider);
    invalidate(assetSubAccountTreeProvider);
    invalidate(assetTrendProviderByDateRange);
    invalidate(assetTrendProviderByTimeRange);
    invalidate(accountTransactionsProvider);
    invalidate(assetsSankeyChartDataProvider);
  }

  if (types.contains(AccountType.LIABILITY)) {
    invalidate(totalLiabilitiesProvider);
    invalidate(liabilities.uiLiabilityAccountsProvider);
    invalidate(liabilities.topLiabilityAccountsProvider);
    invalidate(liabilities.liabilityTrendProviderByDateRange);
    invalidate(liabilityAccountTreeProvider);
    invalidate(liabilities.liabilityTrendProviderByTimeRange);
    invalidate(liabilitySubAccountTreeProvider);
    invalidate(liabilities.sankeyChartDataProvider);
  }

  if (types.contains(AccountType.EXPENSE)) {
    invalidate(expensePageDataProvider);
    invalidate(expenseAccountTreeProvider);
    invalidate(expenseChartDataProvider);
    invalidate(detail_page_providers.expenseChartDataProvider);
    invalidate(previousMonthExpenseProviderFamily);
    invalidate(accountMonthlyExpenseProvider);
    invalidate(detail_page_providers.accountMonthlyExpenseProvider);
    invalidate(accountOverallExpenseProvider);
    invalidate(detail_page_providers.accountOverallExpenseProvider);
  }

  if (types.contains(AccountType.INCOME)) {
    invalidate(incomePageDataProvider);
    invalidate(incomeAccountTreeProvider);
    invalidate(incomeChartDataProviderFamily);
    invalidate(income_detail_page_providers.incomeChartDataProvider);
    invalidate(previousMonthIncomeProviderFamily);
    invalidate(accountMonthlyIncomeProvider);
    invalidate(income_detail_page_providers.accountMonthlyIncomeProvider);
    invalidate(accountOverallIncomeProvider);
    invalidate(income_detail_page_providers.accountOverallIncomeProvider);
  }

  if (types.contains(AccountType.EQUITY)) {
    invalidate(equityAccountTreeProvider);
  }
}
