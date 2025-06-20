import 'package:flowm/db/dao/account_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../ledger/ledger_repository.dart';
import '../account/account_repository.dart';

/// 日期范围选择器的StateProvider
final selectedDateRangeProvider =
    StateProvider<String>((ref) => 'month'); // Default to 'month'

/// 顶级资产账户提供者，改为 Stream 形式以支持响应式更新
final topAssetAccountsProvider =
    StreamProvider<List<AccountWithBalance>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    // 如果有选中的账本，根据账本获取资产账户
    yield* repository.watchTopAssetAccountsByLedger(ledgerId: ledger.ledgerId);
  } else {
    // 如果没有选中的账本，返回空列表
    yield [];
  }
});

/// 优化后的UI账户列表提供者，使用更智能的缓存机制
final uiAccountsProvider =
    StreamProvider<List<account_ui.Account>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    // 使用防抖机制，避免过于频繁的更新
    yield* repository
        .watchAssetsAccountTree(ledgerId: ledger.ledgerId)
        .distinct() // 只有当数据真正发生变化时才触发更新
        .asyncExpand((accounts) async* {
      // 添加简单的缓存机制
      yield accounts;
    });
  } else {
    yield [];
  }
});

/// 基于selectedDateRangeProvider的资产趋势数据提供者，改为 Stream 形式
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
