import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../ledger/ledger_repository.dart';
import '../account/account_repository.dart';

class AssetsPageData {
  final List<account_ui.Account> accounts;
  final List<AssetHistoryData> assetTrend;

  const AssetsPageData({
    required this.accounts,
    required this.assetTrend,
  });
}

/// 日期范围选择器的StateProvider
final selectedDateRangeProvider =
    StateProvider.autoDispose<String>((ref) => 'month'); // Default to 'month'

final assetsPageDataProvider =
    FutureProvider.autoDispose<AssetsPageData>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger == null) {
    return const AssetsPageData(accounts: [], assetTrend: []);
  }

  DateTime endDate = DateTime.now();
  DateTime startDate;
  switch (selectedRange) {
    case 'year':
      startDate = DateTime(endDate.year, 1, 1);
      break;
    case '60days':
      startDate = endDate.subtract(const Duration(days: 59));
      break;
    case '30days':
      startDate = endDate.subtract(const Duration(days: 29));
      break;
    case '15days':
      startDate = endDate.subtract(const Duration(days: 14));
      break;
    case 'month':
    default:
      startDate = DateTime(endDate.year, endDate.month, 1);
      break;
  }

  final accountsFuture = repository.getAssetsAccountTree(
      ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
  final assetTrendFuture = repository.getAssetHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: ledger.ledgerId,
    // accountId is null for the main page trend
  );

  final results = await Future.wait([accountsFuture, assetTrendFuture]);

  return AssetsPageData(
    accounts: results[0] as List<account_ui.Account>,
    assetTrend: results[1] as List<AssetHistoryData>,
  );
});

final assetTrendProviderByDateRange = FutureProvider.autoDispose
    .family<List<AssetHistoryData>, int?>((ref, accountId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger == null) {
    return [];
  }

  DateTime endDate = DateTime.now();
  DateTime startDate;

  switch (selectedRange) {
    case 'year':
      startDate = DateTime(endDate.year, 1, 1);
      break;
    case '60days':
      startDate = endDate.subtract(const Duration(days: 59));
      break;
    case '30days':
      startDate = endDate.subtract(const Duration(days: 29));
      break;
    case '15days':
      startDate = endDate.subtract(const Duration(days: 14));
      break;
    case 'month':
    default:
      startDate = DateTime(endDate.year, endDate.month, 1);
      break;
  }

  return repository.getAssetHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: ledger.ledgerId,
    accountId: accountId,
  );
});
