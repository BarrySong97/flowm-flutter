import 'dart:async';

import 'package:flowm/db/dao/account_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_transform/stream_transform.dart';
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
    StateProvider<String>((ref) => 'month'); // Default to 'month'

final assetsPageDataProvider = StreamProvider<AssetsPageData>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final ledgerFuture = ref.watch(selectedLedgerProvider.future);

  return Stream.fromFuture(ledgerFuture).asyncExpand((ledger) {
    if (ledger == null) {
      return Stream.value(const AssetsPageData(accounts: [], assetTrend: []));
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

    final accountsStream =
        repository.watchAssetsAccountTree(ledgerId: ledger.ledgerId);
    final assetTrendStream = repository.watchAssetHistoryByTimeRange(
      startDate,
      endDate,
      ledgerId: ledger.ledgerId,
      // accountId is null for the main page trend
    );

    return accountsStream.combineLatest(assetTrendStream, (accounts, trend) {
      return AssetsPageData(accounts: accounts, assetTrend: trend);
    });
  });
});
final assetTrendProviderByDateRange =
    StreamProvider.family<List<AssetHistoryData>, int?>(
        (ref, accountId) async* {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger == null) {
    yield [];
    return;
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

  yield* repository.watchAssetHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: ledger.ledgerId,
    accountId: accountId,
  );
});
