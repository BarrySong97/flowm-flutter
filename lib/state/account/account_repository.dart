import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'package:flowm/data/accounts/account_balance_query.dart';
import 'package:flowm/data/accounts/account_command_service.dart';
import 'package:flowm/data/accounts/account_tree_query.dart';
import 'package:flowm/domain/accounts/account_models.dart';
import 'package:flowm/features/accounts/application/account_presentation_mapper.dart';
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
  isSystemAccount,
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
    return repository.getAssetsAccountTree(
        ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
  } else {
    return [];
  }
});

/// 根据一级账户ID获取资产账户子树
final assetSubAccountTreeProvider = FutureProvider.family
    .autoDispose<List<account_ui.Account>, int>((ref, parentId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getAssetsAccountTree(
        ledgerId: ledger.ledgerId,
        parentId: parentId,
        currencySymbol: ledger.currencySymbol);
  } else {
    return [];
  }
});

/// 根据一级账户ID获取负债账户子树
final liabilitySubAccountTreeProvider = FutureProvider.family
    .autoDispose<List<account_ui.Account>, int>((ref, parentId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getLiabilityAccountTree(
        ledgerId: ledger.ledgerId,
        parentId: parentId,
        currencySymbol: ledger.currencySymbol);
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
    return repository.getLiabilityAccountTree(
        ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
  } else {
    return [];
  }
});

/// 提供支出账户树，改为 Future 形式
final expenseAccountTreeProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final ledger = await ref.watch(selectedLedgerProvider.future);

  if (ledger != null) {
    return repository.getExpenseAccountTree(
        ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
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
    return repository.getIncomeAccountTree(
        ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
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
    return repository.getEquityAccountTree(
        ledgerId: ledger.ledgerId, currencySymbol: ledger.currencySymbol);
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
  late final AccountBalanceQuery _accountBalanceQuery;
  late final AccountCommandService _accountCommandService;
  late final AccountTreeQuery _accountTreeQuery;
  late final AccountPresentationMapper _accountPresentationMapper;

  AccountRepository(this._accountDao, this._transactionDao) {
    _accountBalanceQuery = AccountBalanceQuery(_accountDao);
    _accountCommandService = AccountCommandService(_accountDao);
    _accountTreeQuery = AccountTreeQuery(_accountDao, _accountBalanceQuery);
    _accountPresentationMapper = const AccountPresentationMapper();
  }

  /// 获取所有账户
  Future<List<Account>> getAllAccounts() =>
      _accountCommandService.getAllAccounts();

  /// 获取账户余额
  Future<double> getAccountBalance(int accountId) =>
      _accountBalanceQuery.getAccountBalance(accountId);

  /// 监听所有账户（响应式流）
  Stream<List<Account>> watchAllAccounts() =>
      _accountCommandService.watchAllAccounts();

  Stream<List<account_ui.Account>> _watchUiAccountTree({
    required AccountTreeType type,
    int? ledgerId,
    String currencySymbol = '¥',
  }) {
    if (ledgerId == null) {
      return Stream.value(<account_ui.Account>[]);
    }

    return _accountTreeQuery
        .watchAccountTree(type: type, ledgerId: ledgerId)
        .map((nodes) => _accountPresentationMapper.toUiAccounts(
              nodes,
              currencySymbol: currencySymbol,
            ));
  }

  Future<List<account_ui.Account>> _getUiAccountTree({
    required AccountTreeType type,
    int? ledgerId,
    int? parentId,
    String currencySymbol = '¥',
  }) async {
    if (ledgerId == null) {
      return [];
    }

    final nodes = await _accountTreeQuery.getAccountTree(
      type: type,
      ledgerId: ledgerId,
      parentId: parentId,
    );
    return _accountPresentationMapper.toUiAccounts(
      nodes,
      currencySymbol: currencySymbol,
    );
  }

  /// 监听UI展示所需的资产账户树（已优化版本）
  Stream<List<account_ui.Account>> watchAssetsAccountTree({int? ledgerId}) {
    return _watchUiAccountTree(type: AccountTreeType.asset, ledgerId: ledgerId);
  }

  /// 监听负债账户树
  Stream<List<account_ui.Account>> watchLiabilityAccountTree({int? ledgerId}) {
    return _watchUiAccountTree(
        type: AccountTreeType.liability, ledgerId: ledgerId);
  }

  /// 监听支出账户树
  Stream<List<account_ui.Account>> watchExpenseAccountTree({int? ledgerId}) {
    return _watchUiAccountTree(
        type: AccountTreeType.expense, ledgerId: ledgerId);
  }

  /// 监听收入账户树
  Stream<List<account_ui.Account>> watchIncomeAccountTree({int? ledgerId}) {
    return _watchUiAccountTree(
        type: AccountTreeType.income, ledgerId: ledgerId);
  }

  /// 监听权益账户树
  Stream<List<account_ui.Account>> watchEquityAccountTree({int? ledgerId}) {
    return _watchUiAccountTree(
        type: AccountTreeType.equity, ledgerId: ledgerId);
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
  Future<Account?> getAccountById(int id) =>
      _accountCommandService.getAccountById(id);

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
        AppLogger.debug(
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
          AppLogger.debug(
              '[AccountRepository] getAssetHistoryByTime: Account with ID $accountId not found in ledger $ledgerId or does not belong to it.');
          return []; // 指定的账户ID无效或不属于该账本
        }

        // 确保找到的账户是资产类型，如果不是，则没有可处理的资产历史
        if (rootAccountForTree.accountType != AccountType.ASSET) {
          AppLogger.debug(
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
        AppLogger.debug(
            '[AccountRepository] getAssetHistoryByTime: No ASSET accounts found to process after filtering.');
        return [];
      }

      // 3. 优化版本：使用单次查询获取所有需要的数据
      return await _getOptimizedAssetHistory(
          start, end, targetAssetAccounts, ledgerId);
    } catch (e, s) {
      AppLogger.debug('[AccountRepository] Error in getAssetHistoryByTime: $e');
      AppLogger.debug('[AccountRepository] Stacktrace: $s');
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

      // 先尝试使用更兼容的批量查询方法
      return await _getBatchOptimizedAssetHistory(start, end, accountIds);
    } catch (e, s) {
      AppLogger.debug(
          '[AccountRepository] Error in _getOptimizedAssetHistory: $e');
      AppLogger.debug('[AccountRepository] Stacktrace: $s');

      // 如果优化查询失败，回退到原来的方法
      AppLogger.debug('[AccountRepository] Falling back to original method...');
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
      AppLogger.debug(
          '[AccountRepository] Error in _getBatchOptimizedAssetHistory: $e');
      AppLogger.debug('[AccountRepository] Stacktrace: $s');
      // 发生错误时，回退到老方法以保证功能可用性
      AppLogger.debug(
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
    bool isDefaultAsset = false,
  }) async {
    final accountId = await _accountDao.insertAccount(AccountsCompanion.insert(
      accountName: name,
      fullPath: fullPath,
      accountType: type,
      ledgerId: ledgerId,
      parentAccountId:
          parentId == null ? const Value.absent() : Value(parentId),
      isActive: Value(isActive),
      defaultUseAssets: Value(isDefaultAsset),
    ));

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
    bool isDefaultAsset = false,
  }) async {
    String fullPath;
    String parentPath = '';

    if (parentId != null) {
      // 通过 parentId 查找一级账户
      final parentAccount = await _accountDao.getAccountById(parentId);
      if (parentAccount != null) {
        // 如果一级账户存在，使用其 fullPath 作为新路径的前缀
        parentPath = parentAccount.fullPath;
      }
    }

    // 如果父路径为空（即没有一级账户或一级账户未找到），新账户的 fullPath 就是其名称
    // 否则，路径是 "父路径:新账户名"
    fullPath = parentPath.isEmpty ? name : '$parentPath:$name';

    // 调用底层的 createAccount 方法来插入新账户到数据库
    final accountId = await createAccount(
      name: name,
      fullPath: fullPath,
      type: type,
      ledgerId: ledgerId,
      parentId: parentId,
      isDefaultAsset: false, // 先创建为非默认状态
    );

    // 如果需要设置为默认资产账户，则调用专门的方法
    if (isDefaultAsset && type == AccountType.ASSET) {
      await setDefaultAssetAccount(accountId, ledgerId);
    }

    // createAccount 已经会更新 Home Widget，这里不需要重复调用
    return accountId;
  }

  /// 创建带初始金额的新账户
  Future<int> addNewAccountWithInitialAmount({
    required String name,
    required AccountType type,
    required int ledgerId,
    int? parentId,
    double? initialAmount,
    bool isDefaultAsset = false,
  }) async {
    return await _accountDao.db.transaction(() async {
      // 1. 先创建账户
      final accountId = await addNewAccount(
        name: name,
        type: type,
        ledgerId: ledgerId,
        parentId: parentId,
        isDefaultAsset: isDefaultAsset,
      );

      // 2. 如果有初始金额且大于0，创建期初余额交易
      if (initialAmount != null && initialAmount > 0) {
        // 获取期初余额账户
        final openingBalanceAccount = await getOpeningBalanceAccount(ledgerId);
        if (openingBalanceAccount == null) {
          throw Exception('期初余额账户未找到，无法创建初始金额交易');
        }

        if (type != AccountType.ASSET && type != AccountType.LIABILITY) {
          throw Exception('只有资产和负债账户支持设置初始金额');
        }

        // 创建交易记录
        final transactionId = await _transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            transactionDate: DateTime.now(),
            description: Value('账户期初余额 - $name'),
          ),
        );

        // 创建分录记录
        if (type == AccountType.ASSET) {
          // 资产账户：期初余额减少，新账户增加
          await _accountDao.db.postings.insertOne(
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: openingBalanceAccount.accountId,
              amount: -initialAmount,
            ),
          );
          await _accountDao.db.postings.insertOne(
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: accountId,
              amount: initialAmount,
            ),
          );
        } else if (type == AccountType.LIABILITY) {
          // 负债账户：期初余额增加，新账户减少（负债增加）
          await _accountDao.db.postings.insertOne(
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: openingBalanceAccount.accountId,
              amount: initialAmount,
            ),
          );
          await _accountDao.db.postings.insertOne(
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: accountId,
              amount: -initialAmount,
            ),
          );
        }
      }

      return accountId;
    });
  }

  /// 更新一个现有账户，并处理路径更新
  Future<void> editAccount({
    required int accountId,
    required String name,
    required AccountType type,
    required int ledgerId,
    int? parentId,
    bool? isDefaultAsset,
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

    // 如果需要设置为默认资产账户
    if (isDefaultAsset == true && type == AccountType.ASSET) {
      await setDefaultAssetAccount(accountId, ledgerId);
    }

    // After updating, we might need to update the full path of all children
    final children = await _accountDao.getChildAccounts(accountId);
    for (final child in children) {
      await _updateChildPaths(child, newFullPath, ledgerId);
    }

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
    bool? isDefaultAsset,
  }) async {
    final account = await _accountDao.getAccountById(id);
    if (account == null) return false;

    final result = await _accountDao.updateAccount(AccountsCompanion(
      accountId: Value(id),
      accountName: name != null ? Value(name) : const Value.absent(),
      accountType: type != null ? Value(type) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
    ));

    // 如果需要设置为默认资产账户
    if (result &&
        isDefaultAsset == true &&
        account.accountType == AccountType.ASSET) {
      await setDefaultAssetAccount(id, account.ledgerId);
    }

    // 获取账户的 ledgerId 以更新 App Group 数据
    if (result) {
      _updateHomeWidgetAccountData(account.ledgerId);
    }

    return result;
  }

  /// 删除账户
  Future<DeleteAccountResult> deleteAccount(int id) async {
    try {
      // 获取账户信息用于后续更新 App Group
      final account = await _accountDao.getAccountById(id);
      if (account == null) {
        return DeleteAccountResult.error;
      }

      // 检查是否为系统保护账户（期初余额账户）
      if (account.accountType == AccountType.EQUITY &&
          (account.accountName == '期初余额' ||
              account.accountName == 'Opening Balance')) {
        return DeleteAccountResult.isSystemAccount;
      }

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
        // 删除成功后更新 App Group 数据
        _updateHomeWidgetAccountData(account.ledgerId);
        return DeleteAccountResult.success;
      } else {
        return DeleteAccountResult.error;
      }
    } catch (e) {
      AppLogger.debug('删除账户失败: $e');
      return DeleteAccountResult.error;
    }
  }

  /// 获取账户树
  ///
  /// [ledgerId] 账本ID.
  /// [parentId] 如果提供，则只获取该一级账户下的子树.
  /// 返回一个包含所有顶级账户及其子账户的嵌套结构
  Future<List<AccountWithChildren>> getAccountTree(
      {int? ledgerId, int? parentId}) async {
    // 获取所有账户
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId ?? 0);

    // 找出顶级账户（一级账户ID与`parentId`匹配的账户）
    // 如果 parentId 为 null, 则查找没有一级账户的顶级账户.
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
        // 获取所有与该账本相关的支出账户
        final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
        final expenseAccountIds = allAccounts
            .where((account) => account.accountType == AccountType.EXPENSE)
            .map((acc) => acc.accountId)
            .toList();

        if (expenseAccountIds.isEmpty) {
          return 0.0;
        }

        // 计算支出账户在此期间的总金额
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
        AppLogger.debug(
            '[AccountRepository] Error in watchExpenseInPeriod: $e');
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
        AppLogger.debug('[AccountRepository] Error in watchIncomeInPeriod: $e');
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
      AppLogger.debug('[AccountRepository] Error in getExpenseInPeriod: $e');
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
      AppLogger.debug('[AccountRepository] Error in getIncomeInPeriod: $e');
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
      AppLogger.debug(
          '[AccountRepository] Error in getTotalLiabilitiesByLedger: $e');
      return 0.0;
    }
  }

  /// 获取顶级资产账户（考虑特定账本）（Stream版本）- 优化版本
  Stream<List<AccountWithBalance>> watchTopAssetAccountsByLedger(
      {int? limit, required int ledgerId}) {
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((_) async {
      try {
        return _accountBalanceQuery.getTopAssetAccountsByLedger(
          ledgerId: ledgerId,
          limit: limit,
        );
      } catch (e, s) {
        AppLogger.debug(
            '[AccountRepository] Error in watchTopAssetAccountsByLedger: $e');
        AppLogger.debug('[AccountRepository] Stacktrace: $s');
        return <AccountWithBalance>[];
      }
    });
  }

  /// 获取顶级资产账户（考虑特定账本）
  Future<List<AccountWithBalance>> getTopAssetAccountsByLedger(
      {int? limit, required int ledgerId}) async {
    return _accountBalanceQuery.getTopAssetAccountsByLedger(
      ledgerId: ledgerId,
      limit: limit,
    );
  }

  /// 根据账户类型获取账户
  Stream<List<Account>> watchAccountsByType(AccountType type) =>
      _accountDao.watchAccountsByType(type);

  /// 获取UI展示所需的账户树
  /// 将数据库中的账户转换为UI组件所需的格式
  Future<List<account_ui.Account>> getAssetsAccountTree(
      {int? ledgerId, int? parentId, String currencySymbol = '¥'}) async {
    try {
      return _getUiAccountTree(
        type: AccountTreeType.asset,
        ledgerId: ledgerId,
        parentId: parentId,
        currencySymbol: currencySymbol,
      );
    } catch (e) {
      AppLogger.debug('[AccountRepository] Error in getAssetsAccountTree: $e');
      return []; // 发生错误时返回空列表
    }
  }

  /// 获取负债账户树
  Future<List<account_ui.Account>> getLiabilityAccountTree(
      {int? ledgerId, int? parentId, String currencySymbol = '¥'}) async {
    try {
      return _getUiAccountTree(
        type: AccountTreeType.liability,
        ledgerId: ledgerId,
        parentId: parentId,
        currencySymbol: currencySymbol,
      );
    } catch (e) {
      return [];
    }
  }

  /// 获取支出账户树
  Future<List<account_ui.Account>> getExpenseAccountTree(
      {int? ledgerId, String currencySymbol = '¥'}) async {
    try {
      return _getUiAccountTree(
        type: AccountTreeType.expense,
        ledgerId: ledgerId,
        currencySymbol: currencySymbol,
      );
    } catch (e) {
      return [];
    }
  }

  /// 获取收入账户树
  Future<List<account_ui.Account>> getIncomeAccountTree(
      {int? ledgerId, String currencySymbol = '¥'}) async {
    try {
      return _getUiAccountTree(
        type: AccountTreeType.income,
        ledgerId: ledgerId,
        currencySymbol: currencySymbol,
      );
    } catch (e) {
      return [];
    }
  }

  /// 获取权益账户树
  Future<List<account_ui.Account>> getEquityAccountTree(
      {int? ledgerId, String currencySymbol = '¥'}) async {
    try {
      return _getUiAccountTree(
        type: AccountTreeType.equity,
        ledgerId: ledgerId,
        currencySymbol: currencySymbol,
      );
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

  /// 获取期初余额账户
  Future<Account?> getOpeningBalanceAccount(int ledgerId) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final openingBalanceAccount = allAccounts.firstWhere(
        (account) =>
            account.accountType == AccountType.EQUITY &&
            (account.accountName == '期初余额' ||
                account.accountName == 'Opening Balance'),
        orElse: () => throw Exception('期初余额账户未找到'),
      );
      return openingBalanceAccount;
    } catch (e) {
      AppLogger.debug('[AccountRepository] 获取期初余额账户失败: $e');
      return null;
    }
  }

  /// 获取最近使用的资产账户
  Future<Account?> getLastUsedAssetAccount(int ledgerId) async {
    try {
      // 获取最近的一笔交易中使用的资产账户
      final result = await _accountDao.customSelect(
        '''
        SELECT DISTINCT a.account_id, a.ledger_id, a.parent_account_id,
               a.account_name, a.full_path, a.account_type, a.is_active,
               a.default_use_assets, a.created_at, t.transaction_date
        FROM accounts a
        JOIN postings p ON a.account_id = p.account_id
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE a.ledger_id = ?
          AND a.account_type = ?
          AND a.is_active = 1
        ORDER BY t.transaction_date DESC, t.created_at DESC
        LIMIT 1
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.ASSET.name),
        ],
      ).getSingleOrNull();

      if (result != null) {
        return Account(
          accountId: result.read<int>('account_id'),
          ledgerId: result.read<int>('ledger_id'),
          parentAccountId: result.readNullable<int>('parent_account_id'),
          accountName: result.read<String>('account_name'),
          fullPath: result.read<String>('full_path'),
          accountType: AccountType.values.firstWhere(
            (type) => type.name == result.read<String>('account_type'),
            orElse: () => AccountType.ASSET,
          ),
          isActive: result.read<bool>('is_active'),
          defaultUseAssets: result.readNullable<bool>('default_use_assets'),
          createdAt: result.read<DateTime>('created_at'),
        );
      }

      return null;
    } catch (e) {
      AppLogger.debug('[AccountRepository] 获取最近使用的资产账户失败: $e');
      return null;
    }
  }

  /// 获取默认资产账户
  Future<Account?> getDefaultAssetAccount(int ledgerId) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);

      // 1. 首先尝试找到设置为默认的资产账户
      final defaultAssetAccount = allAccounts
          .where((account) =>
              account.accountType == AccountType.ASSET &&
              account.isActive &&
              (account.defaultUseAssets ?? false))
          .firstOrNull;

      if (defaultAssetAccount != null) {
        AppLogger.debug(
            '[AccountRepository] 使用设置的默认资产账户: ${defaultAssetAccount.accountName}');
        return defaultAssetAccount;
      }

      // 2. 如果没有设置默认账户，尝试获取最近使用的资产账户
      final lastUsedAssetAccount = await getLastUsedAssetAccount(ledgerId);
      if (lastUsedAssetAccount != null) {
        AppLogger.debug(
            '[AccountRepository] 使用最近使用的资产账户: ${lastUsedAssetAccount.accountName}');
        return lastUsedAssetAccount;
      }

      // 3. 如果没有历史记录，返回第一个活跃的叶子资产账户（优先选择没有子账户的账户）
      final activeAssetAccounts = allAccounts
          .where((account) =>
              account.accountType == AccountType.ASSET && account.isActive)
          .toList();

      // 找出所有叶子账户（没有子账户的账户）
      final leafAssetAccounts = activeAssetAccounts.where((account) {
        // 检查是否有其他账户以此账户为一级账户
        final hasChildren = allAccounts
            .any((child) => child.parentAccountId == account.accountId);
        return !hasChildren;
      }).toList();

      // 优先选择叶子账户
      final firstAssetAccount = leafAssetAccounts.isNotEmpty
          ? leafAssetAccounts.first
          : activeAssetAccounts.firstOrNull;

      if (firstAssetAccount != null) {
        final accountType =
            leafAssetAccounts.contains(firstAssetAccount) ? '叶子资产账户' : '资产账户';
        AppLogger.debug(
            '[AccountRepository] 使用第一个活跃的$accountType: ${firstAssetAccount.accountName}');
      }

      return firstAssetAccount;
    } catch (e) {
      AppLogger.debug('[AccountRepository] 获取默认资产账户失败: $e');
      return null;
    }
  }

  /// 设置默认资产账户（确保只有一个默认账户）
  Future<void> setDefaultAssetAccount(int accountId, int ledgerId) async {
    try {
      await _accountDao.db.transaction(() async {
        // 首先将该账本下所有资产账户的defaultUseAssets设置为false
        await _accountDao.customUpdate(
          'UPDATE accounts SET default_use_assets = 0 WHERE ledger_id = ? AND account_type = ?',
          variables: [
            Variable.withInt(ledgerId),
            Variable.withString(AccountType.ASSET.name),
          ],
        );

        // 然后将指定账户的defaultUseAssets设置为true
        await _accountDao.customUpdate(
          'UPDATE accounts SET default_use_assets = 1 WHERE account_id = ?',
          variables: [
            Variable.withInt(accountId),
          ],
        );
      });

      _updateHomeWidgetAccountData(ledgerId);
    } catch (e) {
      AppLogger.debug('[AccountRepository] 设置默认资产账户失败: $e');
      rethrow;
    }
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
