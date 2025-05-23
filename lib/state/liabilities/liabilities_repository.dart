import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../database/database_provider.dart';
import '../ledger/ledger_repository.dart';

// StateProvider for the selected date range string
final selectedDateRangeProvider =
    StateProvider<String>((ref) => 'month'); // Default to 'month'

/// 顶级负债账户提供者，缓存获取的负债账户数据
final topLiabilityAccountsProvider =
    FutureProvider<List<AccountWithBalance>>((ref) async {
  final repository = ref.watch(liabilitiesRepositoryProvider);

  // 先尝试获取当前选中的账本
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger != null) {
    // 如果有选中的账本，根据账本获取负债账户
    return repository.getTopLiabilityAccountsByLedger(
        ledgerId: selectedLedger.ledgerId);
  } else {
    // 如果没有选中的账本，使用原来的方法获取所有负债账户
    return repository.getTopLiabilityAccounts();
  }
});

/// 提供UI负债账户列表，与AccountItem组件兼容
final uiLiabilityAccountsProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  return repository.getLiabilitiesAccountTree(
      ledgerId: selectedLedger?.ledgerId);
});

/// 年度负债趋势数据提供者，用于绘制负债变化曲线图
final yearlyLiabilityTrendProvider =
    FutureProvider<List<LiabilityHistoryData>>((ref) async {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    return [];
  }

  return repository.getYearlyLiabilityHistory(
      ledgerId: selectedLedger.ledgerId);
});

// 基于日期范围的负债趋势提供者
final liabilityTrendProviderByDateRange =
    FutureProvider.family<List<LiabilityHistoryData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(liabilitiesRepositoryProvider);
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

  return repository.getLiabilityHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 负债仓库提供者，用于封装负债相关的数据库操作
final liabilitiesRepositoryProvider = Provider<LiabilitiesRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  return LiabilitiesRepository(accountDao);
});

/// 负债仓库类
class LiabilitiesRepository {
  final AccountDao _accountDao;

  LiabilitiesRepository(this._accountDao);

  /// 获取UI展示所需的负债账户树
  Future<List<account_ui.Account>> getLiabilitiesAccountTree(
      {int? ledgerId}) async {
    try {
      // 获取账户树，先构建完整的层级关系
      final accountTree = await getAccountTree(ledgerId: ledgerId);

      // 只保留负债类型的账户
      final liabilityAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.LIABILITY)
          .toList();

      // 递归转换为UI需要的Account格式
      final result = await _convertAccountsToUIFormat(liabilityAccounts);
      return result;
    } catch (e) {
      return [];
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
      final double directBalance =
          (await _accountDao.getAccountBalance(acc.account.accountId)).abs();

      double childrensTotalAmount = 0.0;
      List<account_ui.Account>? uiChildren;

      if (acc.children.isNotEmpty) {
        uiChildren = await _convertAccountsToUIFormat(acc.children);
        for (final childUiAccount in uiChildren) {
          childrensTotalAmount += childUiAccount.amount;
        }
      }

      final double totalAmountForUI = directBalance + childrensTotalAmount;

      results.add(account_ui.Account(
        id: acc.account.accountId,
        name: acc.account.accountName,
        amount: totalAmountForUI,
        children: uiChildren,
        currencySymbol: '¥',
      ));
    }

    return results;
  }

  /// 获取所有叶子负债账户（按余额降序排序）
  Future<List<AccountWithBalance>> getTopLiabilityAccounts({int? limit}) async {
    try {
      // 获取所有活跃的负债账户
      final allAccounts = await _accountDao.getAllAccounts();
      final liabilityAccounts = allAccounts
          .where((account) =>
              account.accountType == AccountType.LIABILITY && account.isActive)
          .toList();

      if (liabilityAccounts.isEmpty) {
        return [];
      }

      // 计算每个负债账户的余额
      final List<AccountWithBalance> accountsWithBalance = [];
      for (final account in liabilityAccounts) {
        final balance =
            (await _accountDao.getAccountBalance(account.accountId)).abs();
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
    } catch (e) {
      print('[LiabilitiesRepository] Error in getTopLiabilityAccounts: $e');
      return [];
    }
  }

  /// 获取指定时间段内的负债历史数据
  Future<List<LiabilityHistoryData>> getLiabilityHistoryByTimeRange(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) async {
    return getLiabilityHistoryByTime(start, end,
        ledgerId: ledgerId, accountId: accountId);
  }

  /// 根据时间获取负债历史数据
  Future<List<LiabilityHistoryData>> getLiabilityHistoryByTime(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) async {
    try {
      List<Account> targetLiabilityAccounts = [];

      final allAccountsInLedger =
          await _accountDao.getAccountsByLedgerId(ledgerId);
      if (allAccountsInLedger.isEmpty) {
        print(
            '[LiabilitiesRepository] getLiabilityHistoryByTime: No accounts found in ledger $ledgerId.');
        return [];
      }

      if (accountId != null) {
        Account? rootAccountForTree;
        try {
          rootAccountForTree = allAccountsInLedger.firstWhere(
            (acc) => acc.accountId == accountId && acc.ledgerId == ledgerId,
          );
        } catch (e) {
          print(
              '[LiabilitiesRepository] getLiabilityHistoryByTime: Account with ID $accountId not found in ledger $ledgerId or does not belong to it.');
          return [];
        }

        if (rootAccountForTree.accountType != AccountType.LIABILITY) {
          print(
              '[LiabilitiesRepository] getLiabilityHistoryByTime: Specified account ID $accountId is not a LIABILITY account.');
          return [];
        }

        final accountTree =
            _buildAccountTree(rootAccountForTree, allAccountsInLedger);
        final allRelevantAccountsFromTree =
            _flattenAccountTreeHelper(accountTree);

        targetLiabilityAccounts = allRelevantAccountsFromTree
            .where((acc) =>
                acc.accountType == AccountType.LIABILITY &&
                acc.ledgerId == ledgerId)
            .toList();
      } else {
        targetLiabilityAccounts = allAccountsInLedger
            .where((account) => account.accountType == AccountType.LIABILITY)
            .toList();
      }

      if (targetLiabilityAccounts.isEmpty) {
        print(
            '[LiabilitiesRepository] getLiabilityHistoryByTime: No LIABILITY accounts found to process after filtering.');
        return [];
      }

      final List<LiabilityHistoryData> history = [];
      for (DateTime currentDate = start;
          currentDate.isBefore(end.add(const Duration(days: 1)));
          currentDate = currentDate.add(const Duration(days: 1))) {
        double dailyTotalLiabilities = 0.0;
        for (final account in targetLiabilityAccounts) {
          dailyTotalLiabilities +=
              await _getAccountBalanceAtDate(account.accountId, currentDate);
        }
        history.add(LiabilityHistoryData(
            date: currentDate, totalLiabilities: dailyTotalLiabilities));
      }
      return history;
    } catch (e, s) {
      print('[LiabilitiesRepository] Error in getLiabilityHistoryByTime: $e');
      print('[LiabilitiesRepository] Stacktrace: $s');
      return [];
    }
  }

  /// 获取年度负债历史数据
  Future<List<LiabilityHistoryData>> getYearlyLiabilityHistory(
      {required int ledgerId}) async {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    return getLiabilityHistoryByTime(oneYearAgo, now, ledgerId: ledgerId);
  }

  /// 获取指定账户在指定日期时的余额
  Future<double> _getAccountBalanceAtDate(int accountId, DateTime date) async {
    try {
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

      return (result.read<double?>('balance') ?? 0.0).abs();
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取账户树
  Future<List<AccountWithChildren>> getAccountTree({int? ledgerId}) async {
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId ?? 0);
    final rootAccounts = allAccounts
        .where((account) => account.parentAccountId == null)
        .toList();

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

  // 辅助方法：扁平化账户树，获取节点及其所有子孙账户
  List<Account> _flattenAccountTreeHelper(AccountWithChildren treeNode) {
    final List<Account> accounts = [treeNode.account];
    for (final child in treeNode.children) {
      accounts.addAll(_flattenAccountTreeHelper(child));
    }
    return accounts;
  }

  /// 获取顶级负债账户（考虑特定账本）
  Future<List<AccountWithBalance>> getTopLiabilityAccountsByLedger(
      {int? limit, required int ledgerId}) async {
    try {
      final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId);
      final liabilityAccounts = allAccounts
          .where((account) =>
              account.accountType == AccountType.LIABILITY && account.isActive)
          .toList();

      if (liabilityAccounts.isEmpty) {
        print(
            '[LiabilitiesRepository] getTopLiabilityAccountsByLedger: No active liability accounts found in ledger $ledgerId.');
        return [];
      }

      final List<AccountWithBalance> accountsWithBalance = [];
      for (final account in liabilityAccounts) {
        final balance =
            (await _accountDao.getAccountBalance(account.accountId)).abs();
        accountsWithBalance.add(
          AccountWithBalance(
            account: account,
            balance: balance,
          ),
        );
      }

      accountsWithBalance.sort((a, b) => b.balance.compareTo(a.balance));

      return limit != null
          ? accountsWithBalance.take(limit).toList()
          : accountsWithBalance;
    } catch (e, s) {
      print(
          '[LiabilitiesRepository] Error in getTopLiabilityAccountsByLedger: $e');
      print('[LiabilitiesRepository] Stacktrace: $s');
      return [];
    }
  }
}

/// 负债历史数据点，用于负债趋势图
class LiabilityHistoryData {
  final DateTime date;
  final double totalLiabilities;

  LiabilityHistoryData({
    required this.date,
    required this.totalLiabilities,
  });

  String get formattedDate {
    return '${date.year}/${date.month}/${date.day}';
  }
}

/// 带有子账户的账户模型
class AccountWithChildren {
  final Account account;
  final List<AccountWithChildren> children;

  AccountWithChildren({required this.account, required this.children});
}
