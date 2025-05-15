import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../database/database_provider.dart';

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
  return repository.getTopAssetAccounts();
});

/// 提供UI账户列表，与AccountItem组件兼容
final uiAccountsProvider =
    FutureProvider<List<account_ui.Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAssetsAccountTree();
});

/// 年度资产趋势数据提供者，用于绘制资产变化曲线图
final yearlyAssetTrendProvider =
    FutureProvider<List<AssetHistoryData>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getYearlyAssetHistory();
});

// Renamed and modified provider that fetches asset trend data based on selectedDateRangeProvider
final assetTrendProviderByDateRange =
    FutureProvider<List<AssetHistoryData>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);

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
  // For 'custom', you might need another provider to hold custom start/end dates
  // or expand this logic. For now, it defaults to 'month'.
  // Ensure startDate is not after endDate, which can happen for "month" at the start of a new month if not handled.
  // However, our logic for 'month' (DateTime(endDate.year, endDate.month, 1)) is fine.

  return repository.getAssetHistoryByTimeRange(startDate, endDate);
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
  Future<List<account_ui.Account>> getAssetsAccountTree() async {
    try {
      // 获取账户树，先构建完整的层级关系
      final accountTree = await getAccountTree();

      // 只保留资产类型的账户
      final assetAccounts = accountTree
          .where((acc) => acc.account.accountType == AccountType.ASSET)
          .toList();

      // 递归转换为UI需要的Account格式
      final result = await _convertAccountsToUIFormat(assetAccounts);
      return result;
    } catch (e) {
      print('获取资产账户树时出错: $e');
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
      double balance = 0.0;
      List<account_ui.Account>? children;

      // 如果有子账户，先递归处理子账户
      if (acc.children.isNotEmpty) {
        children = await _convertAccountsToUIFormat(acc.children);

        // 父账户余额就是所有子账户余额之和
        for (final child in children) {
          balance += child.amount;
        }
      } else {
        // 只有叶子账户才直接查询余额
        balance = await _accountDao.getAccountBalance(acc.account.accountId);
      }

      // 创建UI需要的Account对象
      results.add(account_ui.Account(
        name: acc.account.accountName,
        amount: balance,
        children: children,
        currencySymbol: '¥', // 默认使用人民币符号
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

  /// 根据时间获取资产历史数据
  Future<List<AssetHistoryData>> getAssetHistoryByTime(
      DateTime start, DateTime end) async {
    final allAssetAccounts =
        await _accountDao.watchAccountsByType(AccountType.ASSET).first;
    if (allAssetAccounts.isEmpty) {
      return [];
    }

    // 获取所有作为父账户的账户ID
    final parentAccountIds = await _accountDao
        .customSelect(
          'SELECT DISTINCT parent_account_id FROM accounts WHERE parent_account_id IS NOT NULL',
        )
        .get()
        .then((rows) =>
            rows.map((row) => row.read<int>('parent_account_id')).toSet());

    // 过滤出叶子资产账户
    final leafAssetAccounts = allAssetAccounts
        .where((account) => !parentAccountIds.contains(account.accountId))
        .toList();

    if (leafAssetAccounts.isEmpty) {
      // 如果没有叶子资产账户（例如，所有资产账户都是其他账户的父账户，或者没有资产账户）
      // 根据需求，这里可以返回空列表，或者有其他处理逻辑
      // 当前行为：如果没有叶子资产账户，则返回空历史记录
      return [];
    }

    final List<AssetHistoryData> history = [];
    // Iterate from start date to end date, day by day
    for (DateTime currentDate = start;
        currentDate.isBefore(end.add(const Duration(days: 1)));
        currentDate = currentDate.add(const Duration(days: 1))) {
      double dailyTotalAssets = 0.0;
      for (final account in leafAssetAccounts) {
        // 使用叶子账户进行计算
        dailyTotalAssets +=
            await _getAccountBalanceAtDate(account.accountId, currentDate);
      }
      history.add(
          AssetHistoryData(date: currentDate, totalAssets: dailyTotalAssets));
    }
    return history;
  }

  /// 获取年度资产历史数据
  Future<List<AssetHistoryData>> getYearlyAssetHistory() async {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    return getAssetHistoryByTime(oneYearAgo, now);
  }

  /// 获取指定时间段内的资产历史数据
  Future<List<AssetHistoryData>> getAssetHistoryByTimeRange(
      DateTime start, DateTime end) async {
    return getAssetHistoryByTime(start, end);
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
      print('获取指定日期账户余额时出错: $e');
      return 0.0;
    }
  }

  /// 创建新账户
  Future<int> createAccount({
    required String name,
    required String fullPath,
    required AccountType type,
    int? parentId,
    bool isActive = true,
  }) {
    return _accountDao.insertAccount(AccountsCompanion.insert(
      accountName: name,
      fullPath: fullPath,
      accountType: type,
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
  Future<List<AccountWithChildren>> getAccountTree() async {
    // 获取所有账户
    final allAccounts = await _accountDao.getAllAccounts();

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

  /// 获取指定时间段内的总支出
  ///
  /// 1. 获取所有叶子支出账户
  /// 2. 计算这些账户在指定时间段内的支出总和
  Future<double> getExpenseInPeriod(DateTime start, DateTime end) async {
    // 1. 获取所有账户并筛选出支出账户
    final allAccounts = await _accountDao.getAllAccounts();
    final expenseAccounts = allAccounts
        .where((acc) => acc.accountType == AccountType.EXPENSE)
        .toList();

    if (expenseAccounts.isEmpty) {
      return 0.0; // 没有支出账户，总支出为0
    }

    // 获取所有作为父账户的账户ID
    final parentAccountIds = await _accountDao
        .customSelect(
          'SELECT DISTINCT parent_account_id FROM accounts WHERE parent_account_id IS NOT NULL',
        )
        .get()
        .then((rows) =>
            rows.map((row) => row.read<int>('parent_account_id')).toSet());

    // 筛选出叶子支出账户
    final leafExpenseAccounts = expenseAccounts
        .where((account) => !parentAccountIds.contains(account.accountId))
        .toList();

    if (leafExpenseAccounts.isEmpty) {
      // 如果没有叶子支出账户 (例如，所有支出账户都是父账户，或没有支出账户)
      return 0.0;
    }

    double totalExpenses = 0.0;

    for (final account in leafExpenseAccounts) {
      try {
        // 构建SQL查询，查询指定日期范围内该账户的所有交易金额总和
        // 对于支出账户，amount 通常是正数，代表支出金额
        final result = await _accountDao.customSelect(
          '''
          SELECT SUM(p.amount) as period_expense
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id = ? 
          AND t.transaction_date >= ?
          AND t.transaction_date <= ?
          ''',
          variables: [
            Variable.withInt(account.accountId),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
        ).getSingle();

        totalExpenses += result.read<double?>('period_expense') ?? 0.0;
      } catch (e) {
        print('获取账户 ${account.accountId} 在时间段 $start - $end 的支出时出错: $e');
        //可以选择继续计算其他账户或抛出异常
      }
    }
    return totalExpenses;
  }

  /// 获取指定时间段内的总收入
  ///
  /// 1. 获取所有叶子收入账户
  /// 2. 计算这些账户在指定时间段内的收入总和
  Future<double> getIncomeInPeriod(DateTime start, DateTime end) async {
    // 1. 获取所有账户并筛选出收入账户
    final allAccounts = await _accountDao.getAllAccounts();
    final incomeAccounts = allAccounts
        .where((acc) => acc.accountType == AccountType.INCOME)
        .toList();

    if (incomeAccounts.isEmpty) {
      return 0.0; // 没有收入账户，总收入为0
    }

    // 获取所有作为父账户的账户ID
    final parentAccountIds = await _accountDao
        .customSelect(
          'SELECT DISTINCT parent_account_id FROM accounts WHERE parent_account_id IS NOT NULL',
        )
        .get()
        .then((rows) =>
            rows.map((row) => row.read<int>('parent_account_id')).toSet());

    // 筛选出叶子收入账户
    final leafIncomeAccounts = incomeAccounts
        .where((account) => !parentAccountIds.contains(account.accountId))
        .toList();

    if (leafIncomeAccounts.isEmpty) {
      // 如果没有叶子收入账户
      return 0.0;
    }

    double totalIncome = 0.0;

    for (final account in leafIncomeAccounts) {
      try {
        // 构建SQL查询，查询指定日期范围内该账户的所有交易金额总和
        // 对于收入账户，amount 通常是负数 (贷方)
        final result = await _accountDao.customSelect(
          """
          SELECT SUM(p.amount) as period_income
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id = ? 
          AND t.transaction_date >= ?
          AND t.transaction_date <= ?
          """,
          variables: [
            Variable.withInt(account.accountId),
            Variable.withDateTime(start),
            Variable.withDateTime(end),
          ],
        ).getSingle();

        // 收入金额在数据库中为负，所以取反得到正数收入
        totalIncome -= result.read<double?>('period_income') ?? 0.0;
      } catch (e) {
        print('获取账户 ${account.accountId} 在时间段 $start - $end 的收入时出错: $e');
        //可以选择继续计算其他账户或抛出异常
      }
    }
    return totalIncome;
  }

  Future<double> getTotalLiabilities() {
    return _accountDao.getTotalLiabilities();
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
