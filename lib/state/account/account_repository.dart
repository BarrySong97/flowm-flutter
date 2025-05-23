import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../../components/common/time_range_selector.dart';
import '../database/database_provider.dart';
import '../ledger/ledger_repository.dart';

// StateProvider for the selected date range string
final selectedDateRangeProvider =
    StateProvider<String>((ref) => 'month'); // Default to 'month'

/// 账户仓库提供者，用于封装账户相关的数据库操作
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  return AccountRepository(accountDao);
});

/// 顶级资产账户提供者，缓存获取的资产账户数据
/// 这个提供者会缓存getTopAssetAccounts的结果，避免重复请求
final topAssetAccountsProvider =
    FutureProvider<List<AccountWithBalance>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);

  // 先尝试获取当前选中的账本
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger != null) {
    // 如果有选中的账本，根据账本获取资产账户
    return repository.getTopAssetAccountsByLedger(
        ledgerId: selectedLedger.ledgerId);
  } else {
    // 如果没有选中的账本，使用原来的方法获取所有资产账户
    return repository.getTopAssetAccounts();
  }
});

/// 提供UI账户列表，与AccountItem组件兼容
final uiAccountsProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  return repository.getAssetsAccountTree(ledgerId: selectedLedger?.ledgerId);
});

/// 年度资产趋势数据提供者，用于绘制资产变化曲线图
final yearlyAssetTrendProvider =
    FutureProvider<List<AssetHistoryData>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    return [];
  }

  return repository.getYearlyAssetHistory(ledgerId: selectedLedger.ledgerId);
});

// Renamed and modified provider that fetches asset trend data based on selectedDateRangeProvider
final assetTrendProviderByDateRange =
    FutureProvider.family<List<AssetHistoryData>, int?>((ref, accountId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    return [];
  }

  DateTime endDate = DateTime.now();
  DateTime startDate;

  switch (selectedRange) {
    case 'year':
      startDate = DateTime(endDate.year, 1, 1);
      break;
    case '60days':
      startDate =
          endDate.subtract(const Duration(days: 59)); // 59 + today = 60 days
      break;
    case '30days':
      startDate = endDate.subtract(const Duration(days: 29));
      break;
    case '15days':
      startDate = endDate.subtract(const Duration(days: 14));
      break;
    case 'month':
    default: // Default to 'month'
      startDate = DateTime(endDate.year, endDate.month, 1);
      break;
  }

  return repository.getAssetHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

// 基于TimeRange类型的资产趋势数据提供者
final assetTrendProviderByTimeRange = FutureProvider.family<
    List<AssetHistoryData>,
    ({int? accountId, TimeRange timeRange})>((ref, params) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    return [];
  }

  DateTime endDate = DateTime.now();
  DateTime startDate;

  switch (params.timeRange) {
    case TimeRange.all:
      // 获取所有历史数据，从一年前开始
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
    ledgerId: selectedLedger.ledgerId,
    accountId: params.accountId,
  );
});

/// 指定时间段内的资产历史数据提供者，用于绘制资产变化曲线图

/// 账户仓库类
///
/// 封装与账户相关的所有数据库操作，提供更高级别的业务逻辑方法
class AccountRepository {
  final AccountDao _accountDao;

  AccountRepository(this._accountDao);

  /// 获取所有账户
  Future<List<Account>> getAllAccounts() => _accountDao.getAllAccounts();

  /// 监听所有账户（响应式流）
  Stream<List<Account>> watchAllAccounts() => _accountDao.watchAllAccounts();

  /// 获取UI展示所需的账户树
  /// 将数据库中的账户转换为UI组件所需的格式
  Future<List<account_ui.Account>> getAssetsAccountTree({int? ledgerId}) async {
    try {
      // 获取账户树，先构建完整的层级关系
      final accountTree = await getAccountTree(ledgerId: ledgerId);

      // 只保留资产类型的账户
      final assetAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.ASSET)
          .toList();

      // 递归转换为UI需要的Account格式
      final result = await _convertAccountsToUIFormat(assetAccounts);
      return result;
    } catch (e) {
      return []; // 发生错误时返回空列表
    }
  }

  // 递归将AccountWithChildren转换为UI格式的Account并计算余额
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
        amount: totalAmountForUI, // 使用新计算的总金额
        children: uiChildren, // 传递已经处理过的UI子账户列表
        currencySymbol: '¥', // 使用账户的货币代码，默认为人民币符号
      ));
    }

    return results;
  }

  /// 根据账户类型获取账户
  Stream<List<Account>> watchAccountsByType(AccountType type) =>
      _accountDao.watchAccountsByType(type);

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

  /// 根据时间获取资产历史数据
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

      final List<AssetHistoryData> history = [];
      // 3. 迭代日期范围，计算每日总资产
      for (DateTime currentDate = start;
          currentDate.isBefore(end.add(const Duration(days: 1)));
          currentDate = currentDate.add(const Duration(days: 1))) {
        double dailyTotalAssets = 0.0;
        for (final account in targetAssetAccounts) {
          // _getAccountBalanceAtDate 会计算单个账户在指定日期的余额（包含其自身所有记账）
          dailyTotalAssets +=
              await _getAccountBalanceAtDate(account.accountId, currentDate);
        }
        history.add(
            AssetHistoryData(date: currentDate, totalAssets: dailyTotalAssets));
      }
      return history;
    } catch (e, s) {
      print('[AccountRepository] Error in getAssetHistoryByTime: $e');
      print('[AccountRepository] Stacktrace: $s');
      return [];
    }
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

  /// 创建新账户
  Future<int> createAccount({
    required String name,
    required String fullPath,
    required AccountType type,
    required int ledgerId,
    int? parentId,
    bool isActive = true,
  }) {
    return _accountDao.insertAccount(AccountsCompanion.insert(
      accountName: name,
      fullPath: fullPath,
      accountType: type,
      ledgerId: ledgerId,
      parentAccountId:
          parentId == null ? const Value.absent() : Value(parentId),
      isActive: Value(isActive),
    ));
  }

  /// 更新账户
  Future<bool> updateAccount({
    required int id,
    String? name,
    AccountType? type,
    bool? isActive,
  }) {
    return _accountDao.updateAccount(AccountsCompanion(
      accountId: Value(id),
      accountName: name != null ? Value(name) : const Value.absent(),
      accountType: type != null ? Value(type) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
    ));
  }

  /// 删除账户
  Future<bool> deleteAccount(int id) async {
    // 检查是否有子账户
    final children = await _accountDao.getChildAccounts(id);
    if (children.isNotEmpty) {
      // 如果有子账户，不允许删除
      return false;
    }

    // 没有子账户，执行删除
    final result = await _accountDao.deleteAccount(id);
    return result > 0;
  }

  /// 获取账户树
  ///
  /// 返回一个包含所有顶级账户及其子账户的嵌套结构
  Future<List<AccountWithChildren>> getAccountTree({int? ledgerId}) async {
    // 获取所有账户
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId ?? 0);

    // 找出顶级账户（没有父账户的账户）
    final rootAccounts = allAccounts
        .where((account) => account.parentAccountId == null)
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

  /// 获取指定时间段内的支出总额
  Future<double> getExpenseInPeriod(
      int ledgerId, DateTime start, DateTime end) async {
    try {
      // 获取所有与该账本相关的资产账户
      final assetAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final assetAccountsList = assetAccounts
          .where((account) => account.accountType == AccountType.ASSET)
          .toList();

      if (assetAccountsList.isEmpty) return 0.0;

      // 计算资产账户在此期间的支出（负值交易）
      double totalExpense = 0.0;
      for (final account in assetAccountsList) {
        final accountExpense =
            await _getAccountExpenseInPeriod(account.accountId, start, end);
        totalExpense += accountExpense;
      }
      return totalExpense;
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取指定时间段内的收入总额
  Future<double> getIncomeInPeriod(
      int ledgerId, DateTime start, DateTime end) async {
    try {
      // 获取所有与该账本相关的资产账户
      final assetAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final assetAccountsList = assetAccounts
          .where((account) => account.accountType == AccountType.ASSET)
          .toList();

      if (assetAccountsList.isEmpty) return 0.0;

      // 计算资产账户在此期间的收入（正值交易）
      double totalIncome = 0.0;
      for (final account in assetAccountsList) {
        final accountIncome =
            await _getAccountIncomeInPeriod(account.accountId, start, end);
        totalIncome += accountIncome;
      }
      return totalIncome;
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取账户指定时间段内的支出
  Future<double> _getAccountExpenseInPeriod(
      int accountId, DateTime start, DateTime end) async {
    try {
      final result = await _accountDao.customSelect(
        '''
        SELECT SUM(p.amount) as expense
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id = ? 
        AND t.transaction_date BETWEEN ? AND ?
        AND p.amount < 0
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
      ).getSingle();

      return (result.read<double?>('expense') ?? 0.0).abs(); // 转为正值
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取账户指定时间段内的收入
  Future<double> _getAccountIncomeInPeriod(
      int accountId, DateTime start, DateTime end) async {
    try {
      final result = await _accountDao.customSelect(
        '''
        SELECT SUM(p.amount) as income
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id = ? 
        AND t.transaction_date BETWEEN ? AND ?
        AND p.amount > 0
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withDateTime(start),
          Variable.withDateTime(end),
        ],
      ).getSingle();

      return result.read<double?>('income') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取总负债（原始版本，不需要ledgerId）
  Future<double> getTotalLiabilities() {
    return _accountDao.getTotalLiabilities();
  }

  /// 获取总负债（考虑特定账本）
  Future<double> getTotalLiabilitiesByLedger(int ledgerId) async {
    try {
      // 获取所有与该账本相关的负债账户
      final liabilityAccounts =
          await _accountDao.getAccountsByLedgerId(ledgerId);
      final liabilityAccountsList = liabilityAccounts
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
      return 0.0;
    }
  }

  /// 获取顶级资产账户（考虑特定账本）
  Future<List<AccountWithBalance>> getTopAssetAccountsByLedger(
      {int? limit, required int ledgerId}) async {
    try {
      // 获取所有与该账本相关的活跃资产账户
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final assetAccounts = allAccounts
          .where((account) =>
              account.accountType == AccountType.ASSET && account.isActive)
          .toList();

      if (assetAccounts.isEmpty) {
        print(
            '[AccountRepository] getTopAssetAccountsByLedger: No active asset accounts found in ledger $ledgerId.');
        return [];
      }

      // 计算每个资产账户的余额 (不再只计算叶子节点)
      final List<AccountWithBalance> accountsWithBalance = [];
      for (final account in assetAccounts) {
        // _accountDao.getAccountBalance 应该能正确计算单个账户的总余额（包含其所有记账）
        final balance = await _accountDao.getAccountBalance(account.accountId);
        accountsWithBalance.add(
          AccountWithBalance(
            account: account,
            balance: balance,
          ),
        );
      }

      // 按余额降序排序
      accountsWithBalance.sort((a, b) => b.balance.compareTo(a.balance));

      // 如果指定了limit，则返回前limit个
      return limit != null
          ? accountsWithBalance.take(limit).toList()
          : accountsWithBalance;
    } catch (e, s) {
      print('[AccountRepository] Error in getTopAssetAccountsByLedger: $e');
      print('[AccountRepository] Stacktrace: $s');
      return [];
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
