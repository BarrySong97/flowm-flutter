import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/dao/transaction_dao.dart';
import '../../db/tables/account_table.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../../components/common/time_range_selector.dart';
import '../database/database_provider.dart';
import '../ledger/ledger_repository.dart';

/// 删除账户结果枚举
enum DeleteAccountResult {
  success,
  hasChildAccounts,
  hasRelatedTransactions,
  error,
}

/// 账户仓库提供者，用于封装账户相关的数据库操作
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  final transactionDao = ref.watch(transactionDaoProvider);
  return AccountRepository(accountDao, transactionDao);
});

/// 提供资产账户树，改为 Future 形式
final assetsAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getAssetsAccountTree(ledgerId: ledger.ledgerId);
  } else {
    return [];
  }
});

/// 根据父账户ID获取资产账户子树
final assetSubAccountTreeProvider = FutureProvider.family
    .autoDispose<List<account_ui.Account>, int>((ref, parentId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getAssetsAccountTree(
        ledgerId: ledger.ledgerId, parentId: parentId);
  } else {
    return [];
  }
});

/// 根据父账户ID获取负债账户子树
final liabilitySubAccountTreeProvider = FutureProvider.family
    .autoDispose<List<account_ui.Account>, int>((ref, parentId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getLiabilityAccountTree(
        ledgerId: ledger.ledgerId, parentId: parentId);
  } else {
    return [];
  }
});

/// 提供负债账户树，改为 Future 形式
final liabilityAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getLiabilityAccountTree(ledgerId: ledger.ledgerId);
  } else {
    return [];
  }
});

/// 提供费用账户树，改为 Future 形式
final expenseAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getExpenseAccountTree(ledgerId: ledger.ledgerId);
  } else {
    return [];
  }
});

/// 提供收入账户树，改为 Future 形式
final incomeAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getIncomeAccountTree(ledgerId: ledger.ledgerId);
  } else {
    return [];
  }
});

/// 提供权益账户树，改为 Future 形式
final equityAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getEquityAccountTree(ledgerId: ledger.ledgerId);
  } else {
    return [];
  }
});

/// 年度资产趋势数据提供者，改为 Stream 形式
final yearlyAssetTrendProvider =
    StreamProvider<List<AssetHistoryData>>((ref) async* {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    yield* repository.watchYearlyAssetHistory(ledgerId: ledger.ledgerId);
  } else {
    yield [];
  }
});

// 基于TimeRange类型的资产趋势数据提供者
final assetTrendProviderByTimeRange = FutureProvider.family<
    List<AssetHistoryData>,
    ({int? accountId, TimeRange timeRange})>((ref, params) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger == null) {
    return [];
  }

  DateTime endDate = DateTime.now();
  DateTime startDate;

  switch (params.timeRange) {
    case TimeRange.all:
      startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
      break;
    case TimeRange.thisYear:
      startDate = DateTime(endDate.year, 1, 1);
      break;
    case TimeRange.this3Months:
      startDate = DateTime(endDate.year, endDate.month - 3, endDate.day);
      if (startDate.isAfter(endDate)) {
        startDate = DateTime(endDate.year - 1, endDate.month + 9, endDate.day);
      }
      break;
    case TimeRange.this90Days:
      startDate = endDate.subtract(const Duration(days: 89));
      break;
    case TimeRange.thisMonth:
    default:
      startDate = DateTime(endDate.year, endDate.month, 1);
      break;
  }

  return repository.getAssetHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: ledger.ledgerId,
    accountId: params.accountId,
  );
});

/// 指定时间段内的资产历史数据提供者，用于绘制资产变化曲线图

/// 账户仓库类
///
/// 封装与账户相关的所有数据库操作，提供更高级别的业务逻辑方法
class AccountRepository {
  final AccountDao _accountDao;
  final TransactionDao _transactionDao;

  // 添加缓存机制
  final Map<String, List<account_ui.Account>> _accountTreeCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  // 为资产账户余额添加专门的缓存
  final Map<String, List<AccountWithBalance>> _assetAccountsCache = {};
  final Map<String, DateTime> _assetCacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const Duration _assetCacheExpiration =
      Duration(minutes: 2); // 资产缓存过期时间稍短

  AccountRepository(this._accountDao, this._transactionDao);

  /// 获取所有账户
  Future<List<Account>> getAllAccounts() => _accountDao.getAllAccounts();

  /// 获取账户余额
  Future<double> getAccountBalance(int accountId) =>
      _accountDao.getAccountBalance(accountId);

  /// 监听所有账户（响应式流）
  Stream<List<Account>> watchAllAccounts() => _accountDao.watchAllAccounts();

  /// 监听UI展示所需的资产账户树（已优化版本）
  Stream<List<account_ui.Account>> watchAssetsAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    final cacheKey = 'assets_$ledgerId';

    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((_) async {
      try {
        // 检查缓存是否有效
        final now = DateTime.now();
        final cacheTime = _cacheTimestamps[cacheKey];

        if (cacheTime != null &&
            now.difference(cacheTime) < _cacheExpiration &&
            _accountTreeCache.containsKey(cacheKey)) {
          print('[AccountRepository] 使用缓存的账户树数据');
          return _accountTreeCache[cacheKey]!;
        }

        // 缓存失效，重新计算
        print('[AccountRepository] 重新计算账户树数据');

        // 构建完整的层级关系
        final accountTree = await getAccountTree(ledgerId: ledgerId);

        // 只保留资产类型的账户
        final assetAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.ASSET)
            .toList();

        // 使用优化后的转换方法
        final result =
            await _convertAccountsToUIFormatOptimized(assetAccounts, ledgerId);

        // 更新缓存
        _accountTreeCache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = now;

        return result;
      } catch (e) {
        print('[AccountRepository] Error in watchAssetsAccountTree: $e');
        return <account_ui.Account>[]; // 发生错误时返回空列表
      }
    });
  }

  /// 监听负债账户树
  Stream<List<account_ui.Account>> watchLiabilityAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    return _accountDao
        .watchAccountsByLedgerId(ledgerId)
        .asyncMap((accounts) async {
      try {
        final accountTree = await getAccountTree(ledgerId: ledgerId);
        final liabilityAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.LIABILITY)
            .toList();
        return _convertAccountsToUIFormatWithoutBalance(liabilityAccounts);
      } catch (e) {
        return <account_ui.Account>[];
      }
    });
  }

  /// 监听费用账户树
  Stream<List<account_ui.Account>> watchExpenseAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    return _accountDao
        .watchAccountsByLedgerId(ledgerId)
        .asyncMap((accounts) async {
      try {
        final accountTree = await getAccountTree(ledgerId: ledgerId);
        final expenseAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.EXPENSE)
            .toList();
        return _convertAccountsToUIFormatWithoutBalance(expenseAccounts);
      } catch (e) {
        return <account_ui.Account>[];
      }
    });
  }

  /// 监听收入账户树
  Stream<List<account_ui.Account>> watchIncomeAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    return _accountDao
        .watchAccountsByLedgerId(ledgerId)
        .asyncMap((accounts) async {
      try {
        final accountTree = await getAccountTree(ledgerId: ledgerId);
        final incomeAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.INCOME)
            .toList();
        return _convertAccountsToUIFormatWithoutBalance(incomeAccounts);
      } catch (e) {
        return <account_ui.Account>[];
      }
    });
  }

  /// 监听权益账户树
  Stream<List<account_ui.Account>> watchEquityAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    return _accountDao
        .watchAccountsByLedgerId(ledgerId)
        .asyncMap((accounts) async {
      try {
        final accountTree = await getAccountTree(ledgerId: ledgerId);
        final equityAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.EQUITY)
            .toList();
        return _convertAccountsToUIFormatWithoutBalance(equityAccounts);
      } catch (e) {
        return <account_ui.Account>[];
      }
    });
  }

  /// 监听年度资产历史数据
  Stream<List<AssetHistoryData>> watchYearlyAssetHistory(
      {required int ledgerId}) {
    // 监听所有相关的交易变化
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((transactions) async {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      return getAssetHistoryByTime(oneYearAgo, now, ledgerId: ledgerId);
    });
  }

  /// 监听指定时间段内的资产历史数据
  Stream<List<AssetHistoryData>> watchAssetHistoryByTimeRange(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) {
    // 监听所有相关的交易变化
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((transactions) async {
      return getAssetHistoryByTime(start, end,
          ledgerId: ledgerId, accountId: accountId);
    });
  }

  /// 获取账户详情
  Future<Account?> getAccountById(int id) => _accountDao.getAccountById(id);

  /// 获取所有叶子资产账户（按余额降序排序）
  Future<List<AccountWithBalance>> getTopAssetAccounts({int? limit}) =>
      _accountDao.getTopAssetAccounts(limit: limit);

  /// 获取指定时间段内的资产历史数据
  Future<List<AssetHistoryData>> getAssetHistoryByTimeRange(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) async {
    return getAssetHistoryByTime(start, end,
        ledgerId: ledgerId, accountId: accountId);
  }

  /// 根据时间获取资产历史数据（优化版本）
  Future<List<AssetHistoryData>> getAssetHistoryByTime(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) async {
    try {
      List<Account> targetAssetAccounts = [];

      // 1. 获取账本下的所有账户基础数据
      final allAccountsInLedger =
          await _accountDao.getAccountsByLedgerId(ledgerId);
      if (allAccountsInLedger.isEmpty) {
        print(
            '[AccountRepository] getAssetHistoryByTime: No accounts found in ledger $ledgerId.');
        return [];
      }

      if (accountId != null) {
        // 2a. 如果指定了 accountId，则处理该账户及其子树
        Account? rootAccountForTree;
        try {
          rootAccountForTree = allAccountsInLedger.firstWhere(
            (acc) => acc.accountId == accountId && acc.ledgerId == ledgerId,
          );
        } catch (e) {
          // Element not found
          print(
              '[AccountRepository] getAssetHistoryByTime: Account with ID $accountId not found in ledger $ledgerId or does not belong to it.');
          return []; // 指定的账户ID无效或不属于该账本
        }

        // 确保找到的账户是资产类型，如果不是，则没有可处理的资产历史
        if (rootAccountForTree.accountType != AccountType.ASSET) {
          print(
              '[AccountRepository] getAssetHistoryByTime: Specified account ID $accountId is not an ASSET account.');
          return [];
        }

        final accountTree =
            _buildAccountTree(rootAccountForTree, allAccountsInLedger);
        final allRelevantAccountsFromTree =
            _flattenAccountTreeHelper(accountTree);

        targetAssetAccounts = allRelevantAccountsFromTree
            .where((acc) =>
                acc.accountType == AccountType.ASSET &&
                acc.ledgerId == ledgerId) // 确保是资产类型且属于当前账本
            .toList();
      } else {
        // 2b. 如果没有指定 accountId，则处理账本下所有的资产账户
        targetAssetAccounts = allAccountsInLedger
            .where((account) => account.accountType == AccountType.ASSET)
            .toList();
      }

      if (targetAssetAccounts.isEmpty) {
        print(
            '[AccountRepository] getAssetHistoryByTime: No ASSET accounts found to process after filtering.');
        return [];
      }

      // 3. 优化版本：使用单次查询获取所有需要的数据
      return await _getOptimizedAssetHistory(
          start, end, targetAssetAccounts, ledgerId);
    } catch (e, s) {
      print('[AccountRepository] Error in getAssetHistoryByTime: $e');
      print('[AccountRepository] Stacktrace: $s');
      return [];
    }
  }

  /// 优化的资产历史数据获取方法
  Future<List<AssetHistoryData>> _getOptimizedAssetHistory(DateTime start,
      DateTime end, List<Account> targetAssetAccounts, int ledgerId) async {
    try {
      if (targetAssetAccounts.isEmpty) return [];

      // 构建账户ID列表
      final accountIds =
          targetAssetAccounts.map((acc) => acc.accountId).toList();
      final accountIdPlaceholders = accountIds.map((_) => '?').join(',');

      // 先尝试使用更兼容的批量查询方法
      return await _getBatchOptimizedAssetHistory(start, end, accountIds);
    } catch (e, s) {
      print('[AccountRepository] Error in _getOptimizedAssetHistory: $e');
      print('[AccountRepository] Stacktrace: $s');

      // 如果优化查询失败，回退到原来的方法
      print('[AccountRepository] Falling back to original method...');
      return await _getFallbackAssetHistory(start, end, targetAssetAccounts);
    }
  }

  /// 批量优化的资产历史数据获取方法 (更高效的版本)
  Future<List<AssetHistoryData>> _getBatchOptimizedAssetHistory(
      DateTime start, DateTime end, List<int> accountIds) async {
    try {
      if (accountIds.isEmpty) return [];

      final accountIdPlaceholders = accountIds.map((_) => '?').join(',');

      // 1. 计算起始日期前的总余额
      final initialBalanceResult = await _accountDao.customSelect(
        '''
        SELECT COALESCE(SUM(p.amount), 0) as balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id IN ($accountIdPlaceholders)
        AND t.transaction_date < ?
        ''',
        variables: [
          ...accountIds.map((id) => Variable.withInt(id)),
          Variable.withDateTime(start),
        ],
      ).getSingle();

      double currentBalance =
          initialBalanceResult.read<double?>('balance') ?? 0.0;

      // 2. 获取时间范围内的每日资产变动
      final dailyChangesResult = await _accountDao.customSelect(
        '''
        SELECT 
            t.transaction_date,
            SUM(p.amount) as daily_change
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id IN ($accountIdPlaceholders)
        AND t.transaction_date BETWEEN ? AND ?
        GROUP BY t.transaction_date
        ORDER BY t.transaction_date
        ''',
        variables: [
          ...accountIds.map((id) => Variable.withInt(id)),
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
      ).get();

      final dailyChanges = <DateTime, double>{};
      for (final row in dailyChangesResult) {
        final date = row.read<DateTime>('transaction_date');
        // 将日期标准化为午夜，以避免时间部分引起的问题
        final day = DateTime(date.year, date.month, date.day);
        final change = row.read<double>('daily_change');
        dailyChanges[day] = change;
      }

      // 3. 在内存中计算每一天的资产总额
      final List<AssetHistoryData> history = [];
      for (DateTime currentDate = start;
          currentDate.isBefore(end.add(const Duration(days: 1)));
          currentDate = currentDate.add(const Duration(days: 1))) {
        final day =
            DateTime(currentDate.year, currentDate.month, currentDate.day);
        currentBalance += dailyChanges[day] ?? 0.0;

        history.add(AssetHistoryData(date: day, totalAssets: currentBalance));
      }

      return history;
    } catch (e, s) {
      print('[AccountRepository] Error in _getBatchOptimizedAssetHistory: $e');
      print('[AccountRepository] Stacktrace: $s');
      // 发生错误时，回退到老方法以保证功能可用性
      print(
          '[AccountRepository] Falling back to original method due to error...');
      return await _getFallbackAssetHistory(
          start, end, await _accountDao.getAccountsByIds(accountIds));
    }
  }

  /// 回退方法：原来的实现逻辑（作为备用）
  Future<List<AssetHistoryData>> _getFallbackAssetHistory(
      DateTime start, DateTime end, List<Account> targetAssetAccounts) async {
    final List<AssetHistoryData> history = [];

    // 使用原来的双重循环逻辑
    for (DateTime currentDate = start;
        currentDate.isBefore(end.add(const Duration(days: 1)));
        currentDate = currentDate.add(const Duration(days: 1))) {
      double dailyTotalAssets = 0.0;
      for (final account in targetAssetAccounts) {
        dailyTotalAssets +=
            await _getAccountBalanceAtDate(account.accountId, currentDate);
      }
      history.add(
          AssetHistoryData(date: currentDate, totalAssets: dailyTotalAssets));
    }
    return history;
  }

  // 辅助方法：扁平化账户树，获取节点及其所有子孙账户
  List<Account> _flattenAccountTreeHelper(AccountWithChildren treeNode) {
    final List<Account> accounts = [treeNode.account];
    for (final child in treeNode.children) {
      accounts.addAll(_flattenAccountTreeHelper(child));
    }
    return accounts;
  }

  /// 获取年度资产历史数据
  Future<List<AssetHistoryData>> getYearlyAssetHistory(
      {required int ledgerId}) async {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    return getAssetHistoryByTime(oneYearAgo, now, ledgerId: ledgerId);
  }

  /// 获取指定账户在指定日期时的余额
  ///
  /// 通过查询指定日期之前的所有交易来计算余额
  Future<double> _getAccountBalanceAtDate(int accountId, DateTime date) async {
    try {
      // 构建SQL查询，查询指定日期前该账户的所有交易金额总和
      final result = await _accountDao.customSelect(
        '''
        SELECT SUM(p.amount) as balance 
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id = ? 
        AND t.transaction_date <= ?
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withDateTime(date),
        ],
      ).getSingle();

      return result.read<double?>('balance') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 更新 App Group 账户数据
  Future<void> _updateHomeWidgetAccountData(int ledgerId) async {
    if (kIsWeb) {
      return;
    }
    try {
      // 获取四种类型的账户（不包括 EQUITY）
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);

      final assetAccounts = allAccounts
          .where((account) => account.accountType == AccountType.ASSET)
          .map((acc) => {
                'id': acc.accountId,
                'name': acc.accountName,
                'fullPath': acc.fullPath
              })
          .toList();

      final liabilityAccounts = allAccounts
          .where((account) => account.accountType == AccountType.LIABILITY)
          .map((acc) => {
                'id': acc.accountId,
                'name': acc.accountName,
                'fullPath': acc.fullPath
              })
          .toList();

      final incomeAccounts = allAccounts
          .where((account) => account.accountType == AccountType.INCOME)
          .map((acc) => {
                'id': acc.accountId,
                'name': acc.accountName,
                'fullPath': acc.fullPath
              })
          .toList();

      final expenseAccounts = allAccounts
          .where((account) => account.accountType == AccountType.EXPENSE)
          .map((acc) => {
                'id': acc.accountId,
                'name': acc.accountName,
                'fullPath': acc.fullPath
              })
          .toList();

      debugPrint(
          '[AppGroup] Updating account data: assets=${assetAccounts.length}, liabilities=${liabilityAccounts.length}, income=${incomeAccounts.length}, expense=${expenseAccounts.length}');

      // 为了Shortcut访问，保存JSON格式的数据
      final Map<String, dynamic> accountData = {
        'assetAccounts': assetAccounts,
        'liabilityAccounts': liabilityAccounts,
        'incomeAccounts': incomeAccounts,
        'expenseAccounts': expenseAccounts,
        'lastUpdated': DateTime.now().toIso8601String(),
        'ledgerId': ledgerId,
      };

      // 使用平台通道直接写入到 App Group UserDefaults
      // const platform = MethodChannel('com.flowm.app_group');

      try {
        // await platform.invokeMethod('saveToAppGroup', {
        //   'groupId': 'group.flowm',
        //   'data': {
        //     'accountDataJson': jsonEncode(accountData),
        //     'assetAccounts': jsonEncode(assetAccounts),
        //     'liabilityAccounts': jsonEncode(liabilityAccounts),
        //     'incomeAccounts': jsonEncode(incomeAccounts),
        //     'expenseAccounts': jsonEncode(expenseAccounts),
        //     'ledgerId': ledgerId,
        //     'lastUpdated': DateTime.now().toIso8601String(),
        //   }
        // });

        HomeWidget.setAppGroupId('group.flowm');
        await HomeWidget.saveWidgetData<String>(
            'accountDataJson', jsonEncode(accountData));

        debugPrint(
            '[AppGroup] Account data saved successfully via platform channel');
      } catch (e) {
        debugPrint('[AppGroup] Error saving via platform channel: $e');

        // 作为备选方案，仍然尝试使用 HomeWidget（虽然可能不被 Intent 访问到）
        HomeWidget.setAppGroupId('group.flowm');
        await HomeWidget.saveWidgetData<String>(
            'accountDataJson', jsonEncode(accountData));
        debugPrint('[AppGroup] Fallback: saved via HomeWidget');
      }
    } catch (e) {
      debugPrint('[AppGroup] Error updating account data: $e');
    }
  }

  /// 更新 App Group 账户数据（公共方法）
  Future<void> updateHomeWidgetAccountData(int ledgerId) async {
    await _updateHomeWidgetAccountData(ledgerId);
  }

  /// 测试 App Group 数据写入
  Future<void> testAppGroupDataWrite(int ledgerId) async {
    try {
      debugPrint('[AccountRepository] Testing App Group data write...');

      // 创建测试数据
      final testData = {
        'test': 'Hello from Flutter',
        'timestamp': DateTime.now().toIso8601String(),
        'ledgerId': ledgerId,
      };

      const platform = MethodChannel('com.flowm.app_group');

      await platform.invokeMethod('saveToAppGroup', {
        'groupId': 'group.flowm',
        'data': testData,
      });

      debugPrint('[AccountRepository] Test data written successfully');

      // 然后写入真正的账户数据
      await _updateHomeWidgetAccountData(ledgerId);
    } catch (e) {
      debugPrint('[AccountRepository] Test failed: $e');
    }
  }

  /// 创建新账户
  Future<int> createAccount({
    required String name,
    required String fullPath,
    required AccountType type,
    required int ledgerId,
    int? parentId,
    bool isActive = true,
  }) async {
    final accountId = await _accountDao.insertAccount(AccountsCompanion.insert(
      accountName: name,
      fullPath: fullPath,
      accountType: type,
      ledgerId: ledgerId,
      parentAccountId:
          parentId == null ? const Value.absent() : Value(parentId),
      isActive: Value(isActive),
    ));

    // 创建账户后清理相关缓存，确保数据一致性
    _clearLedgerRelatedCache(ledgerId);
    // 创建账户后更新 App Group 数据
    _updateHomeWidgetAccountData(ledgerId);

    return accountId;
  }

  /// 创建一个新账户，并自动处理 fullPath
  Future<int> addNewAccount({
    required String name,
    required AccountType type,
    required int ledgerId,
    int? parentId,
  }) async {
    String fullPath;
    String parentPath = '';

    if (parentId != null) {
      // 通过 parentId 查找父账户
      final parentAccount = await _accountDao.getAccountById(parentId);
      if (parentAccount != null) {
        // 如果父账户存在，使用其 fullPath 作为新路径的前缀
        parentPath = parentAccount.fullPath;
      }
    }

    // 如果父路径为空（即没有父账户或父账户未找到），新账户的 fullPath 就是其名称
    // 否则，路径是 "父路径:新账户名"
    fullPath = parentPath.isEmpty ? name : '$parentPath:$name';

    // 调用底层的 createAccount 方法来插入新账户到数据库
    final accountId = await createAccount(
      name: name,
      fullPath: fullPath,
      type: type,
      ledgerId: ledgerId,
      parentId: parentId,
    );

    // createAccount 已经会更新 Home Widget，这里不需要重复调用
    return accountId;
  }

  /// 更新一个现有账户，并处理路径更新
  Future<void> editAccount({
    required int accountId,
    required String name,
    required AccountType type,
    required int ledgerId,
    int? parentId,
  }) async {
    String newFullPath;
    String parentPath = '';

    if (parentId != null) {
      final parentAccount = await _accountDao.getAccountById(parentId);
      if (parentAccount != null) {
        parentPath = parentAccount.fullPath;
      }
    }

    newFullPath = parentPath.isEmpty ? name : '$parentPath:$name';

    await _accountDao.updateAccount(AccountsCompanion(
      accountId: Value(accountId),
      accountName: Value(name),
      fullPath: Value(newFullPath),
      accountType: Value(type),
      ledgerId: Value(ledgerId),
      parentAccountId: Value(parentId),
    ));

    // After updating, we might need to update the full path of all children
    final children = await _accountDao.getChildAccounts(accountId);
    for (final child in children) {
      await _updateChildPaths(child, newFullPath, ledgerId);
    }

    // 更新账户后清理相关缓存，确保数据一致性
    _clearLedgerRelatedCache(ledgerId);
    // 更新账户后更新 App Group 数据
    _updateHomeWidgetAccountData(ledgerId);
  }

  // Helper method to recursively update child paths
  Future<void> _updateChildPaths(
      Account parent, String parentNewPath, int ledgerId) async {
    final children = await _accountDao.getChildAccounts(parent.accountId);
    for (final child in children) {
      final newChildPath = '$parentNewPath:${child.accountName}';
      await _accountDao.updateAccount(
        AccountsCompanion(
          accountId: Value(child.accountId),
          fullPath: Value(newChildPath),
          ledgerId: Value(ledgerId),
        ),
      );
      // Recursively update grandchildren
      await _updateChildPaths(child, newChildPath, ledgerId);
    }
  }

  /// 更新账户
  Future<bool> updateAccount({
    required int id,
    String? name,
    AccountType? type,
    bool? isActive,
  }) async {
    final result = await _accountDao.updateAccount(AccountsCompanion(
      accountId: Value(id),
      accountName: name != null ? Value(name) : const Value.absent(),
      accountType: type != null ? Value(type) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
    ));

    // 获取账户的 ledgerId 以更新 App Group 数据
    if (result) {
      final account = await _accountDao.getAccountById(id);
      if (account != null) {
        // 更新账户后清理相关缓存，确保数据一致性
        _clearLedgerRelatedCache(account.ledgerId);
        _updateHomeWidgetAccountData(account.ledgerId);
      }
    }

    return result;
  }

  /// 删除账户
  Future<DeleteAccountResult> deleteAccount(int id) async {
    try {
      // 获取账户信息用于后续更新 App Group
      final account = await _accountDao.getAccountById(id);

      // 检查是否有子账户
      final children = await _accountDao.getChildAccounts(id);
      if (children.isNotEmpty) {
        return DeleteAccountResult.hasChildAccounts;
      }

      // 检查是否有关联的posting记录
      final relatedPostings = await _accountDao.customSelect(
        'SELECT COUNT(*) as count FROM postings WHERE account_id = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();

      final postingCount = relatedPostings.read<int>('count');
      if (postingCount > 0) {
        return DeleteAccountResult.hasRelatedTransactions;
      }

      // 没有子账户和关联的posting，执行删除
      final result = await _accountDao.deleteAccount(id);
      if (result > 0) {
        // 删除成功后清理相关缓存并更新 App Group 数据
        if (account != null) {
          _clearLedgerRelatedCache(account.ledgerId);
          _updateHomeWidgetAccountData(account.ledgerId);
        }
        return DeleteAccountResult.success;
      } else {
        return DeleteAccountResult.error;
      }
    } catch (e) {
      print('删除账户失败: $e');
      return DeleteAccountResult.error;
    }
  }

  /// 获取账户树
  ///
  /// [ledgerId] 账本ID.
  /// [parentId] 如果提供，则只获取该父账户下的子树.
  /// 返回一个包含所有顶级账户及其子账户的嵌套结构
  Future<List<AccountWithChildren>> getAccountTree(
      {int? ledgerId, int? parentId}) async {
    // 获取所有账户
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId ?? 0);

    // 找出顶级账户（父账户ID与`parentId`匹配的账户）
    // 如果 parentId 为 null, 则查找没有父账户的顶级账户.
    final rootAccounts = allAccounts
        .where((account) => account.parentAccountId == parentId)
        .toList();

    // 递归构建账户树
    return rootAccounts.map((root) {
      return _buildAccountTree(root, allAccounts);
    }).toList();
  }

  // 递归构建账户树的辅助方法
  AccountWithChildren _buildAccountTree(
      Account root, List<Account> allAccounts) {
    final children = allAccounts
        .where((account) => account.parentAccountId == root.accountId)
        .map((child) => _buildAccountTree(child, allAccounts))
        .toList();

    return AccountWithChildren(account: root, children: children);
  }

  /// 获取指定时间段内的支出总额（Stream版本）
  Stream<double> watchExpenseInPeriod(
      int ledgerId, DateTime start, DateTime end) {
    // 监听指定账本的所有交易变化
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((transactions) async {
      try {
        // 获取所有与该账本相关的费用账户
        final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
        final expenseAccountIds = allAccounts
            .where((account) => account.accountType == AccountType.EXPENSE)
            .map((acc) => acc.accountId)
            .toList();

        if (expenseAccountIds.isEmpty) {
          return 0.0;
        }

        // 计算费用账户在此期间的总金额
        final result = await _accountDao.customSelect(
          '''
          SELECT SUM(p.amount) as total
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id IN (${expenseAccountIds.map((_) => '?').join(',')})
          AND t.transaction_date BETWEEN ? AND ?
          ''',
          variables: [
            ...expenseAccountIds.map((id) => Variable.withInt(id)),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
        ).getSingle();

        return result.read<double?>('total') ?? 0.0;
      } catch (e) {
        print('[AccountRepository] Error in watchExpenseInPeriod: $e');
        return 0.0;
      }
    });
  }

  /// 获取指定时间段内的收入总额（Stream版本）
  Stream<double> watchIncomeInPeriod(
      int ledgerId, DateTime start, DateTime end) {
    // 监听指定账本的所有交易变化
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((transactions) async {
      try {
        // 获取所有与该账本相关的收入账户
        final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
        final incomeAccountIds = allAccounts
            .where((account) => account.accountType == AccountType.INCOME)
            .map((acc) => acc.accountId)
            .toList();

        if (incomeAccountIds.isEmpty) {
          return 0.0;
        }

        // 计算收入账户在此期间的总金额
        final result = await _accountDao.customSelect(
          '''
          SELECT SUM(p.amount) as total
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id IN (${incomeAccountIds.map((_) => '?').join(',')})
          AND t.transaction_date BETWEEN ? AND ?
          ''',
          variables: [
            ...incomeAccountIds.map((id) => Variable.withInt(id)),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
        ).getSingle();

        // 收入是贷方，金额为负，所以取反
        return -(result.read<double?>('total') ?? 0.0);
      } catch (e) {
        print('[AccountRepository] Error in watchIncomeInPeriod: $e');
        return 0.0;
      }
    });
  }

  /// 获取指定时间段内的支出总额 (Future version)
  Future<double> getExpenseInPeriod(
      int ledgerId, DateTime start, DateTime end) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final expenseAccountIds = allAccounts
          .where((account) => account.accountType == AccountType.EXPENSE)
          .map((acc) => acc.accountId)
          .toList();

      if (expenseAccountIds.isEmpty) {
        return 0.0;
      }

      final result = await _accountDao.customSelect(
        '''
          SELECT SUM(p.amount) as total
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id IN (${expenseAccountIds.map((_) => '?').join(',')})
          AND t.transaction_date BETWEEN ? AND ?
          ''',
        variables: [
          ...expenseAccountIds.map((id) => Variable.withInt(id)),
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
      ).getSingle();

      return result.read<double?>('total') ?? 0.0;
    } catch (e) {
      print('[AccountRepository] Error in getExpenseInPeriod: $e');
      return 0.0;
    }
  }

  /// 获取指定时间段内的收入总额 (Future version)
  Future<double> getIncomeInPeriod(
      int ledgerId, DateTime start, DateTime end) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final incomeAccountIds = allAccounts
          .where((account) => account.accountType == AccountType.INCOME)
          .map((acc) => acc.accountId)
          .toList();

      if (incomeAccountIds.isEmpty) {
        return 0.0;
      }

      final result = await _accountDao.customSelect(
        '''
          SELECT SUM(p.amount) as total
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id IN (${incomeAccountIds.map((_) => '?').join(',')})
          AND t.transaction_date BETWEEN ? AND ?
          ''',
        variables: [
          ...incomeAccountIds.map((id) => Variable.withInt(id)),
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
      ).getSingle();

      return -(result.read<double?>('total') ?? 0.0);
    } catch (e) {
      print('[AccountRepository] Error in getIncomeInPeriod: $e');
      return 0.0;
    }
  }

  /// 获取总负债（考虑特定账本）(Future version)
  Future<double> getTotalLiabilitiesByLedger(int ledgerId) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final liabilityAccountsList = allAccounts
          .where((account) => account.accountType == AccountType.LIABILITY)
          .toList();

      if (liabilityAccountsList.isEmpty) return 0.0;

      double totalLiabilities = 0.0;
      for (final account in liabilityAccountsList) {
        final balance = await _accountDao.getAccountBalance(account.accountId);
        totalLiabilities += balance;
      }

      return totalLiabilities;
    } catch (e) {
      print('[AccountRepository] Error in getTotalLiabilitiesByLedger: $e');
      return 0.0;
    }
  }

  /// 获取顶级资产账户（考虑特定账本）（Stream版本）- 优化版本
  Stream<List<AccountWithBalance>> watchTopAssetAccountsByLedger(
      {int? limit, required int ledgerId}) {
    // 添加防抖机制，避免过于频繁的更新
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .distinct() // 只有当数据真正发生变化时才触发更新
        .asyncMap((transactions) async {
      try {
        final cacheKey = 'assets_${ledgerId}_${limit ?? 'all'}';
        final now = DateTime.now();
        final cacheTime = _assetCacheTimestamps[cacheKey];

        // 当数据库发生变化时，立即清除相关缓存以确保数据实时性
        // 因为 watchAllTransactions 已经使用了 distinct()，这里被触发说明数据真的发生了变化
        print('[AccountRepository] 数据库发生变化，清除账本 $ledgerId 的资产缓存');
        _clearAssetCacheForLedger(ledgerId);

        // 定期清理过期缓存（每20次查询清理一次）
        if (DateTime.now().millisecond % 20 == 0) {
          _cleanupExpiredCache();
        }

        // 重新计算数据（确保获取最新数据）
        print('[AccountRepository] 重新计算资产账户数据');
        final result = await _getTopAssetAccountsByLedgerOptimized(
            limit: limit, ledgerId: ledgerId);

        // 更新缓存
        _assetAccountsCache[cacheKey] = result;
        _assetCacheTimestamps[cacheKey] = now;

        return result;
      } catch (e, s) {
        print('[AccountRepository] Error in watchTopAssetAccountsByLedger: $e');
        print('[AccountRepository] Stacktrace: $s');
        return <AccountWithBalance>[];
      }
    });
  }

  /// 清理指定账本的资产缓存
  void _clearAssetCacheForLedger(int ledgerId) {
    final keysToRemove = <String>[];

    // 找到所有与该账本相关的资产缓存键
    _assetAccountsCache.keys
        .where((key) => key.startsWith('assets_$ledgerId'))
        .forEach((key) {
      keysToRemove.add(key);
    });

    // 清除缓存
    for (final key in keysToRemove) {
      _assetAccountsCache.remove(key);
      _assetCacheTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print('[AccountRepository] 已清除 ${keysToRemove.length} 个资产缓存项');
    }
  }

  /// 清理指定账本的所有相关缓存
  void _clearLedgerRelatedCache(int ledgerId) {
    // 清理资产账户缓存
    _clearAssetCacheForLedger(ledgerId);

    // 清理账户树缓存
    final accountTreeKey = 'assets_$ledgerId';
    _accountTreeCache.remove(accountTreeKey);
    _cacheTimestamps.remove(accountTreeKey);

    print('[AccountRepository] 已清理账本 $ledgerId 的所有相关缓存');
  }

  /// 优化的批量查询方法
  Future<List<AccountWithBalance>> _getTopAssetAccountsByLedgerOptimized(
      {int? limit, required int ledgerId}) async {
    try {
      // 使用单个 SQL 查询一次性获取所有资产账户及其余额
      final result = await _accountDao.customSelect(
        '''
        SELECT 
          a.account_id,
          a.ledger_id,
          a.parent_account_id,
          a.account_name,
          a.full_path,
          a.account_type,
          a.is_active,
          a.created_at,
          COALESCE(SUM(p.amount), 0) as balance
        FROM accounts a
        LEFT JOIN postings p ON a.account_id = p.account_id
        WHERE a.ledger_id = ? 
          AND a.account_type = ? 
          AND a.is_active = 1
        GROUP BY a.account_id, a.ledger_id, a.parent_account_id, a.account_name, 
                 a.full_path, a.account_type, a.is_active, a.created_at
        ORDER BY balance DESC
        ${limit != null ? 'LIMIT ?' : ''}
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.ASSET.name),
          if (limit != null) Variable.withInt(limit),
        ],
      ).get();

      if (result.isEmpty) {
        print(
            '[AccountRepository] _getTopAssetAccountsByLedgerOptimized: No active asset accounts found in ledger $ledgerId.');
        return <AccountWithBalance>[];
      }

      // 构建结果列表
      final List<AccountWithBalance> accountsWithBalance = [];
      for (final row in result) {
        final account = Account(
          accountId: row.read<int>('account_id'),
          ledgerId: row.read<int>('ledger_id'),
          parentAccountId: row.readNullable<int>('parent_account_id'),
          accountName: row.read<String>('account_name'),
          fullPath: row.read<String>('full_path'),
          accountType: AccountType.values.firstWhere(
            (type) => type.name == row.read<String>('account_type'),
            orElse: () => AccountType.ASSET,
          ),
          isActive: row.read<bool>('is_active'),
          createdAt: row.read<DateTime>('created_at'),
        );

        final balance = row.read<double>('balance');

        accountsWithBalance.add(
          AccountWithBalance(
            account: account,
            balance: balance,
          ),
        );
      }

      return accountsWithBalance;
    } catch (e, s) {
      print(
          '[AccountRepository] Error in _getTopAssetAccountsByLedgerOptimized: $e');
      print('[AccountRepository] Stacktrace: $s');
      return <AccountWithBalance>[];
    }
  }

  /// 获取顶级资产账户（考虑特定账本）
  Future<List<AccountWithBalance>> getTopAssetAccountsByLedger(
      {int? limit, required int ledgerId}) async {
    return _getTopAssetAccountsByLedgerOptimized(
        limit: limit, ledgerId: ledgerId);
  }

  // 递归将AccountWithChildren转换为UI格式的Account并计算余额（用于资产账户）
  Future<List<account_ui.Account>> _convertAccountsToUIFormat(
      List<AccountWithChildren> accounts) async {
    if (accounts.isEmpty) {
      return [];
    }

    final List<account_ui.Account> results = [];

    for (final acc in accounts) {
      // 1. 获取当前账户自身的直接余额
      // 我们假设 _accountDao.getAccountBalance 返回的是该账户所有直接记账的总和。
      final double directBalance =
          await _accountDao.getAccountBalance(acc.account.accountId);

      double childrensTotalAmount = 0.0;
      List<account_ui.Account>? uiChildren;

      // 2. 如果有子账户，递归处理子账户并累加其UI显示的金额
      if (acc.children.isNotEmpty) {
        uiChildren = await _convertAccountsToUIFormat(acc.children);
        for (final childUiAccount in uiChildren) {
          // childUiAccount.amount 已经是经过递归计算的完整余额（自身+其子项）
          childrensTotalAmount += childUiAccount.amount;
        }
      }

      // 3. 当前账户在UI上显示的总金额 = 自身直接余额 + 子账户UI显示金额总和
      final double totalAmountForUI = directBalance + childrensTotalAmount;

      // 创建UI需要的Account对象
      results.add(account_ui.Account(
        id: acc.account.accountId,
        name: acc.account.accountName,
        type: acc.account.accountType,
        amount: totalAmountForUI, // 使用新计算的总金额
        children: uiChildren, // 传递已经处理过的UI子账户列表
        currencySymbol: '¥', // 使用账户的货币代码，默认为人民币符号
      ));
    }

    return results;
  }

  /// 优化后的转换方法，使用批量查询避免N+1问题
  Future<List<account_ui.Account>> _convertAccountsToUIFormatOptimized(
      List<AccountWithChildren> accounts, int ledgerId) async {
    if (accounts.isEmpty) {
      return [];
    }

    // 1. 收集所有需要查询余额的账户ID
    final allAccountIds = <int>{};
    void collectAccountIds(List<AccountWithChildren> accountList) {
      for (final acc in accountList) {
        allAccountIds.add(acc.account.accountId);
        if (acc.children.isNotEmpty) {
          collectAccountIds(acc.children);
        }
      }
    }

    collectAccountIds(accounts);

    // 2. 批量查询所有账户的余额
    final balanceMap = await _batchGetAccountBalances(allAccountIds.toList());

    // 3. 递归转换为UI格式，使用预先查询的余额数据
    return _convertAccountsToUIFormatWithBalanceMap(accounts, balanceMap);
  }

  /// 批量获取账户余额，避免N+1查询问题
  Future<Map<int, double>> _batchGetAccountBalances(
      List<int> accountIds) async {
    if (accountIds.isEmpty) return {};

    try {
      // 使用IN查询批量获取所有账户的余额
      final placeholders = accountIds.map((_) => '?').join(',');
      final result = await _accountDao.customSelect(
        '''
        SELECT account_id, COALESCE(SUM(amount), 0) as balance 
        FROM postings 
        WHERE account_id IN ($placeholders)
        GROUP BY account_id
        ''',
        variables: accountIds.map((id) => Variable.withInt(id)).toList(),
      ).get();

      final balanceMap = <int, double>{};

      // 初始化所有账户的余额为0
      for (final accountId in accountIds) {
        balanceMap[accountId] = 0.0;
      }

      // 填充实际的余额数据
      for (final row in result) {
        final accountId = row.read<int>('account_id');
        final balance = row.read<double>('balance');
        balanceMap[accountId] = balance;
      }

      return balanceMap;
    } catch (e) {
      print('[AccountRepository] Error in _batchGetAccountBalances: $e');
      // 返回默认值
      return Map.fromEntries(accountIds.map((id) => MapEntry(id, 0.0)));
    }
  }

  /// 使用预先查询的余额数据转换账户格式
  List<account_ui.Account> _convertAccountsToUIFormatWithBalanceMap(
      List<AccountWithChildren> accounts, Map<int, double> balanceMap) {
    if (accounts.isEmpty) {
      return [];
    }

    final List<account_ui.Account> results = [];

    for (final acc in accounts) {
      // 1. 获取当前账户的直接余额（从缓存中获取）
      final double directBalance = balanceMap[acc.account.accountId] ?? 0.0;

      double childrensTotalAmount = 0.0;
      List<account_ui.Account>? uiChildren;

      // 2. 如果有子账户，递归处理子账户
      if (acc.children.isNotEmpty) {
        uiChildren =
            _convertAccountsToUIFormatWithBalanceMap(acc.children, balanceMap);
        for (final childUiAccount in uiChildren) {
          childrensTotalAmount += childUiAccount.amount;
        }
      }

      // 3. 计算总金额
      final double totalAmountForUI = directBalance + childrensTotalAmount;

      // 创建UI需要的Account对象
      results.add(account_ui.Account(
        id: acc.account.accountId,
        name: acc.account.accountName,
        type: acc.account.accountType,
        amount: totalAmountForUI,
        children: uiChildren,
        currencySymbol: '¥',
      ));
    }

    return results;
  }

  // 递归将AccountWithChildren转换为UI格式的Account但不计算余额（用于非资产账户）
  List<account_ui.Account> _convertAccountsToUIFormatWithoutBalance(
      List<AccountWithChildren> accounts) {
    if (accounts.isEmpty) {
      return [];
    }

    final List<account_ui.Account> results = [];

    for (final acc in accounts) {
      List<account_ui.Account>? uiChildren;

      // 如果有子账户，递归处理子账户
      if (acc.children.isNotEmpty) {
        uiChildren = _convertAccountsToUIFormatWithoutBalance(acc.children);
      }

      // 创建UI需要的Account对象，金额设为0
      results.add(account_ui.Account(
        id: acc.account.accountId,
        name: acc.account.accountName,
        type: acc.account.accountType,
        amount: 0.0, // 不计算余额，设为0
        children: uiChildren,
        currencySymbol: '¥',
        icon: _getAccountIcon(acc.account.accountType), // 根据账户类型设置图标
      ));
    }

    return results;
  }

  // 根据账户类型获取对应的图标
  IconData _getAccountIcon(AccountType accountType) {
    switch (accountType) {
      case AccountType.ASSET:
        return Icons.account_balance_wallet;
      case AccountType.LIABILITY:
        return Icons.credit_card;
      case AccountType.EXPENSE:
        return Icons.trending_down;
      case AccountType.INCOME:
        return Icons.trending_up;
      case AccountType.EQUITY:
        return Icons.pie_chart;
      default:
        return Icons.account_balance;
    }
  }

  /// 根据账户类型获取账户
  Stream<List<Account>> watchAccountsByType(AccountType type) =>
      _accountDao.watchAccountsByType(type);

  /// 获取UI展示所需的账户树
  /// 将数据库中的账户转换为UI组件所需的格式
  Future<List<account_ui.Account>> getAssetsAccountTree(
      {int? ledgerId, int? parentId}) async {
    try {
      if (ledgerId == null) {
        return [];
      }
      // 获取账户树，先构建完整的层级关系
      final accountTree =
          await getAccountTree(ledgerId: ledgerId, parentId: parentId);

      // 只保留资产类型的账户
      final assetAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.ASSET)
          .toList();

      // 递归转换为UI需要的Account格式
      final result =
          await _convertAccountsToUIFormatOptimized(assetAccounts, ledgerId);
      return result;
    } catch (e) {
      print('[AccountRepository] Error in getAssetsAccountTree: $e');
      return []; // 发生错误时返回空列表
    }
  }

  /// 获取负债账户树
  Future<List<account_ui.Account>> getLiabilityAccountTree(
      {int? ledgerId, int? parentId}) async {
    try {
      if (ledgerId == null) {
        return [];
      }
      final accountTree =
          await getAccountTree(ledgerId: ledgerId, parentId: parentId);
      final liabilityAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.LIABILITY)
          .toList();
      return await _convertAccountsToUIFormatOptimized(
          liabilityAccounts, ledgerId);
    } catch (e) {
      return [];
    }
  }

  /// 获取费用账户树
  Future<List<account_ui.Account>> getExpenseAccountTree(
      {int? ledgerId}) async {
    try {
      if (ledgerId == null) {
        return [];
      }
      final accountTree = await getAccountTree(ledgerId: ledgerId);
      final expenseAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.EXPENSE)
          .toList();
      return await _convertAccountsToUIFormatOptimized(
          expenseAccounts, ledgerId);
    } catch (e) {
      return [];
    }
  }

  /// 获取收入账户树
  Future<List<account_ui.Account>> getIncomeAccountTree({int? ledgerId}) async {
    try {
      if (ledgerId == null) {
        return [];
      }
      final accountTree = await getAccountTree(ledgerId: ledgerId);
      final incomeAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.INCOME)
          .toList();
      return await _convertAccountsToUIFormatOptimized(
          incomeAccounts, ledgerId);
    } catch (e) {
      return [];
    }
  }

  /// 获取权益账户树
  Future<List<account_ui.Account>> getEquityAccountTree({int? ledgerId}) async {
    try {
      if (ledgerId == null) {
        return [];
      }
      final accountTree = await getAccountTree(ledgerId: ledgerId);
      final equityAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.EQUITY)
          .toList();
      return await _convertAccountsToUIFormatOptimized(
          equityAccounts, ledgerId);
    } catch (e) {
      return [];
    }
  }

  /// 获取用于生成AI提示词的账户列表
  Future<Map<AccountType, List<Account>>> getAccountsForAIPrompt(
      int ledgerId) async {
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
    final Map<AccountType, List<Account>> accountsMap = {
      AccountType.ASSET: [],
      AccountType.LIABILITY: [],
      AccountType.INCOME: [],
      AccountType.EXPENSE: [],
    };

    for (final account in allAccounts) {
      if (accountsMap.containsKey(account.accountType)) {
        accountsMap[account.accountType]!.add(account);
      }
    }
    return accountsMap;
  }

  /// 清除账户树缓存
  void clearAccountTreeCache([int? ledgerId]) {
    if (ledgerId != null) {
      final cacheKey = 'assets_$ledgerId';
      _accountTreeCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    } else {
      _accountTreeCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// 清理过期的缓存
  void _cleanupExpiredCache() {
    final now = DateTime.now();

    // 清理账户树缓存
    _cacheTimestamps.removeWhere((key, timestamp) {
      final isExpired = now.difference(timestamp) > _cacheExpiration;
      if (isExpired) {
        _accountTreeCache.remove(key);
      }
      return isExpired;
    });

    // 清理资产账户缓存
    _assetCacheTimestamps.removeWhere((key, timestamp) {
      final isExpired = now.difference(timestamp) > _assetCacheExpiration;
      if (isExpired) {
        _assetAccountsCache.remove(key);
      }
      return isExpired;
    });
  }

  /// 手动清理所有缓存
  void clearAllCache() {
    _accountTreeCache.clear();
    _cacheTimestamps.clear();
    _assetAccountsCache.clear();
    _assetCacheTimestamps.clear();
    print('[AccountRepository] 所有缓存已清理');
  }

  /// 清理指定账本的缓存
  void clearLedgerCache(int ledgerId) {
    final keysToRemove = <String>[];

    // 清理账户树缓存
    _accountTreeCache.keys
        .where((key) => key.contains('_$ledgerId'))
        .forEach((key) {
      keysToRemove.add(key);
    });

    // 清理资产账户缓存
    _assetAccountsCache.keys
        .where((key) => key.contains('_$ledgerId'))
        .forEach((key) {
      keysToRemove.add(key);
    });

    for (final key in keysToRemove) {
      _accountTreeCache.remove(key);
      _cacheTimestamps.remove(key);
      _assetAccountsCache.remove(key);
      _assetCacheTimestamps.remove(key);
    }

    print('[AccountRepository] 账本 $ledgerId 的缓存已清理');
  }
}

/// 带有子账户的账户模型
class AccountWithChildren {
  final Account account;
  final List<AccountWithChildren> children;

  AccountWithChildren({required this.account, required this.children});
}

/// 资产历史数据点，用于资产趋势图
class AssetHistoryData {
  final DateTime date;
  final double totalAssets;

  AssetHistoryData({
    required this.date,
    required this.totalAssets,
  });

  // 格式化日期显示
  // 对于日期显示，返回如：5/12 或 2023/5/12 格式
  String get formattedDate {
    // final now = DateTime.now();
    // 如果是今年的日期，只显示月/日
    // if (date.year == now.year) {
    //   return '${date.month}/${date.day}';
    // }
    // 否则显示年/月/日
    return '${date.year}/${date.month}/${date.day}';
  }
}
