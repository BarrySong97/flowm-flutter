import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../../components/account/account_item.dart' as account_ui;
import '../database/database_provider.dart';
import '../ledger/ledger_repository.dart';

// StateProvider for the selected date range string
final selectedDateRangeProvider =
    StateProvider<String>((ref) => 'month'); // Default to 'month'

final liabilitiesAccountTransactionsProvider = StreamProvider.family<
    List<TransactionWithAmount>,
    ({int accountId, TimeRange timeRange})>((ref, params) {
  final liabilitiesRepository = ref.watch(liabilitiesRepositoryProvider);
  return liabilitiesRepository.watchAccountTransactions(
    accountId: params.accountId,
    timeRange: params.timeRange,
  );
});

/// 顶级负债账户提供者，缓存获取的负债账户数据
final topLiabilityAccountsProvider =
    StreamProvider<List<AccountWithBalance>>((ref) async* {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger != null) {
    yield* repository.watchTopLiabilityAccountsByLedger(
        ledgerId: selectedLedger.ledgerId);
  } else {
    yield []; // Or handle as an error, but yielding an empty list is safer
  }
});

/// 提供UI负债账户列表，与AccountItem组件兼容
final uiLiabilityAccountsProvider =
    StreamProvider<List<account_ui.Account>>((ref) async* {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger != null) {
    yield* repository.watchLiabilityAccountTree(
        ledgerId: selectedLedger.ledgerId);
  } else {
    yield [];
  }
});

/// 年度负债趋势数据提供者，用于绘制负债变化曲线图
final yearlyLiabilityTrendProvider =
    StreamProvider<List<LiabilityHistoryData>>((ref) async* {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    yield [];
    return;
  }

  yield* repository.watchYearlyLiabilityHistory(
      ledgerId: selectedLedger.ledgerId);
});

final liabilityTrendProviderByTimeRange = StreamProvider.family<
    List<LiabilityHistoryData>,
    ({int? accountId, TimeRange timeRange})>((ref, params) async* {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
    yield [];
    return;
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

  yield* repository.watchLiabilityHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: params.accountId,
  );
});
// 基于日期范围的负债趋势提供者
final liabilityTrendProviderByDateRange =
    StreamProvider.family<List<LiabilityHistoryData>, int?>(
        (ref, accountId) async* {
  final repository = ref.watch(liabilitiesRepositoryProvider);
  final selectedRange = ref.watch(selectedDateRangeProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);

  if (selectedLedger == null) {
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

  yield* repository.watchLiabilityHistoryByTimeRange(
    startDate,
    endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 负债仓库提供者，用于封装负债相关的数据库操作
final liabilitiesRepositoryProvider = Provider<LiabilitiesRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  final transactionDao = ref.watch(transactionDaoProvider);
  return LiabilitiesRepository(accountDao, transactionDao);
});

/// 负债仓库类
class LiabilitiesRepository {
  final AccountDao _accountDao;
  final TransactionDao _transactionDao;
  LiabilitiesRepository(this._accountDao, this._transactionDao);

  DateTime _getEndDateFromTimeRange(TimeRange timeRange) {
    return DateTime.now();
  }

  Stream<List<TransactionWithAmount>> watchAccountTransactions({
    required int accountId,
    required TimeRange timeRange,
  }) {
    final startDate = _getStartDateFromTimeRange(timeRange);
    final endDate = _getEndDateFromTimeRange(timeRange);

    return _transactionDao.watchTransactionsByAccountAndDateRange(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 根据TimeRange获取开始日期
  DateTime _getStartDateFromTimeRange(TimeRange timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case TimeRange.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TimeRange.this3Months:
        return now.subtract(Duration(days: 90));
      case TimeRange.this90Days:
        return now.subtract(Duration(days: 90));
      case TimeRange.thisYear:
        return DateTime(now.year, 1, 1);
      case TimeRange.all:
        return DateTime(now.year - 10, 1, 1); // 默认返回10年前
      default:
        return now.subtract(Duration(days: 30));
    }
  }

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
      print('[LiabilitiesRepository] Error in getLiabilitiesAccountTree: $e');
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
      // 负债账户的余额通常是负数或零。UI上我们通常希望显示为正数。
      final double directBalance =
          (await _accountDao.getAccountBalance(acc.account.accountId));

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
        type: acc.account.accountType,
        amount: totalAmountForUI.abs(), // 使用绝对值确保UI上显示为正数
        children: uiChildren,
        currencySymbol: '¥',
        icon: _getAccountIcon(acc.account.accountType),
      ));
    }

    return results;
  }

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
            date: currentDate, totalLiabilities: dailyTotalLiabilities.abs()));
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
        final balance = await _accountDao.getAccountBalance(account.accountId);
        accountsWithBalance.add(
          AccountWithBalance(
            account: account,
            balance: balance.abs(), // 使用绝对值
          ),
        );
      }

      accountsWithBalance.sort((a, b) => b.balance.compareTo(a.balance));

      return limit != null
          ? accountsWithBalance.take(limit).toList()
          : accountsWithBalance;
    } catch (e) {
      print(
          '[LiabilitiesRepository] Error in getTopLiabilityAccountsByLedger: $e');
      return [];
    }
  }

  /// 获取指定账户的资产流转数据并转换为 Sankey 图表格式
  ///
  /// [accountId] 目标账户ID
  /// [flow] 流转方向，'in' 表示流入，'out' 表示流出
  /// [limit] 限制返回的交易数量，默认为100
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<SankeyChartData> getAccountFlowForSankey({
    required int accountId,
    required String flow, // 'in' | 'out'
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 获取目标账户信息
    final targetAccount = await _accountDao.getAccountById(accountId);
    if (targetAccount == null) {
      return SankeyChartData(nodes: [], links: []);
    }

    // 获取相关的资产流转数据
    final flows = await _getAssetFlows(
      accountId: accountId,
      flow: flow,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );

    // 转换为 Sankey 图表数据
    return await _convertToSankeyData(flows, targetAccount, flow);
  }

  /// 获取资产流转数据
  Future<List<AssetFlow>> _getAssetFlows({
    required int accountId,
    required String flow,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String dateFilter = '';
    List<Variable> variables = [Variable.withInt(accountId)];

    if (startDate != null && endDate != null) {
      dateFilter = ' AND t.transaction_date BETWEEN ? AND ?';
      variables.addAll([
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ]);
    }

    String query;
    if (flow == 'in') {
      // 查询流入：目标账户作为借方（正数金额）
      query = '''
        SELECT 
          p1.posting_id as source_posting_id,
          p1.account_id as source_account_id,
          a1.account_name as source_account_name,
          a1.account_type as source_account_type,
          a1.parent_account_id as source_parent_account_id,
          a1.full_path as source_full_path,
          p2.posting_id as target_posting_id,
          p2.account_id as target_account_id,
          a2.account_name as target_account_name,
          a2.account_type as target_account_type,
          a2.parent_account_id as target_parent_account_id,
          a2.full_path as target_full_path,
          ABS(p2.amount) as amount,
          t.transaction_date,
          t.description
        FROM postings p1
        JOIN transactions t ON p1.transaction_id = t.transaction_id
        JOIN postings p2 ON p1.transaction_id = p2.transaction_id
        JOIN accounts a1 ON p1.account_id = a1.account_id
        JOIN accounts a2 ON p2.account_id = a2.account_id
        WHERE p2.account_id = ? 
          AND p2.amount > 0 
          AND p1.amount < 0
          AND p1.account_id != p2.account_id
          $dateFilter
        ORDER BY t.transaction_date DESC
        LIMIT $limit
      ''';
    } else {
      // 查询流出：目标账户作为贷方（负数金额）
      query = '''
        SELECT 
          p1.posting_id as source_posting_id,
          p1.account_id as source_account_id,
          a1.account_name as source_account_name,
          a1.account_type as source_account_type,
          a1.parent_account_id as source_parent_account_id,
          a1.full_path as source_full_path,
          p2.posting_id as target_posting_id,
          p2.account_id as target_account_id,
          a2.account_name as target_account_name,
          a2.account_type as target_account_type,
          a2.parent_account_id as target_parent_account_id,
          a2.full_path as target_full_path,
          ABS(p1.amount) as amount,
          t.transaction_date,
          t.description
        FROM postings p1
        JOIN transactions t ON p1.transaction_id = t.transaction_id
        JOIN postings p2 ON p1.transaction_id = p2.transaction_id
        JOIN accounts a1 ON p1.account_id = a1.account_id
        JOIN accounts a2 ON p2.account_id = a2.account_id
        WHERE p1.account_id = ? 
          AND p1.amount < 0 
          AND p2.amount > 0
          AND p1.account_id != p2.account_id
          $dateFilter
        ORDER BY t.transaction_date DESC
        LIMIT $limit
      ''';
    }

    final results =
        await _accountDao.customSelect(query, variables: variables).get();

    return results.map((row) {
      final sourceAccount = Account(
        accountId: row.read<int>('source_account_id'),
        ledgerId: 0, // 这里可以根据需要优化
        parentAccountId: row.read<int?>('source_parent_account_id'),
        accountName: row.read<String>('source_account_name'),
        fullPath: row.read<String>('source_full_path'),
        accountType: AccountType.values.firstWhere(
          (e) => e.name == row.read<String>('source_account_type'),
        ),
        isActive: true,
        createdAt: DateTime.now(),
      );

      final targetAccount = Account(
        accountId: row.read<int>('target_account_id'),
        ledgerId: 0,
        parentAccountId: row.read<int?>('target_parent_account_id'),
        accountName: row.read<String>('target_account_name'),
        fullPath: row.read<String>('target_full_path'),
        accountType: AccountType.values.firstWhere(
          (e) => e.name == row.read<String>('target_account_type'),
        ),
        isActive: true,
        createdAt: DateTime.now(),
      );

      return AssetFlow(
        fromAccount: sourceAccount,
        toAccount: targetAccount,
        amount: row.read<double>('amount'),
        transactionDate: row.read<DateTime>('transaction_date'),
        description: row.read<String?>('description'),
      );
    }).toList();
  }

  List<int> _getAccountPath(int accountId, Map<int, Account> accountMap) {
    final List<int> path = [];
    int? currentId = accountId;

    while (currentId != null) {
      path.add(currentId);
      final account = accountMap[currentId];
      currentId = account?.parentAccountId;
    }

    return path;
  }

  List<HierarchicalLink> _createHierarchicalLinks(
    List<AssetFlow> flows,
    Map<int, Account> accountMap,
    int targetAccountId,
    String flow,
  ) {
    final List<HierarchicalLink> links = [];

    for (final assetFlow in flows) {
      if (flow == 'in') {
        // 流入：其他账户 -> 层级 -> 目标账户
        final sourceAccount = assetFlow.fromAccount;
        final amount = assetFlow.amount;

        // 创建从源账户到其父级账户的链接（如果有父级）
        int currentAccountId = sourceAccount.accountId;
        double currentAmount = amount;

        while (true) {
          final currentAccount = accountMap[currentAccountId];
          if (currentAccount?.parentAccountId != null) {
            // 子级 -> 父级
            links.add(HierarchicalLink(
              sourceId: currentAccountId,
              targetId: currentAccount!.parentAccountId!,
              amount: currentAmount,
            ));
            currentAccountId = currentAccount.parentAccountId!;
          } else {
            // 最终 -> 目标账户
            links.add(HierarchicalLink(
              sourceId: currentAccountId,
              targetId: targetAccountId,
              amount: currentAmount,
            ));
            break;
          }
        }
      } else {
        // 流出：目标账户 -> 层级 -> 其他账户
        final destinationAccount = assetFlow.toAccount;
        final amount = assetFlow.amount;

        // 获取目标账户到最终账户的层级路径
        final destinationPath =
            _getAccountPath(destinationAccount.accountId, accountMap);

        // 从目标账户开始流向最终账户的层级
        int previousAccountId = targetAccountId;

        // 反向遍历路径（从最深层级到根），创建链接
        for (int i = destinationPath.length - 1; i >= 0; i--) {
          final currentAccountId = destinationPath[i];

          links.add(HierarchicalLink(
            sourceId: previousAccountId,
            targetId: currentAccountId,
            amount: amount,
          ));

          previousAccountId = currentAccountId;
        }
      }
    }

    return links;
  }

  Future<void> _loadParentAccounts(
      Set<int> accountIds, Map<int, Account> accountMap) async {
    final parentIds = <int>{};

    // 收集所有父级账户ID
    for (final account in accountMap.values) {
      if (account.parentAccountId != null) {
        parentIds.add(account.parentAccountId!);
      }
    }

    // 递归加载父级账户
    while (parentIds.isNotEmpty) {
      final currentBatchIds = parentIds.toList();
      parentIds.clear();

      for (final parentId in currentBatchIds) {
        if (!accountMap.containsKey(parentId)) {
          final parentAccount = await _accountDao.getAccountById(parentId);
          if (parentAccount != null) {
            accountMap[parentId] = parentAccount;
            if (parentAccount.parentAccountId != null) {
              parentIds.add(parentAccount.parentAccountId!);
            }
          }
        }
      }
    }
  }

  /// 将资产流转数据转换为 Sankey 图表数据（支持层级关系）
  Future<SankeyChartData> _convertToSankeyData(
    List<AssetFlow> flows,
    Account targetAccount,
    String flow,
  ) async {
    print('\n=== AssetsRepository 金额计算调试 ===');
    print(
        '目标账户: ${targetAccount.accountName} (ID: ${targetAccount.accountId})');
    print('流向: $flow');
    print('原始流转数据 (${flows.length}条):');

    for (int i = 0; i < flows.length; i++) {
      final assetFlow = flows[i];
      print(
          '  ${i + 1}. ${assetFlow.fromAccount.accountName} → ${assetFlow.toAccount.accountName}: ¥${assetFlow.amount.toStringAsFixed(2)}');
    }

    if (flows.isEmpty) {
      print('无流转数据');
      return SankeyChartData(nodes: [], links: []);
    }

    // 收集所有相关的账户
    final Set<int> allAccountIds = {};
    final Map<int, Account> accountMap = {};
    final Map<String, double> linkAmounts = {}; // 用于聚合相同链接的金额
    final Map<int, double> nodeAmounts = {}; // 用于计算节点金额

    // 添加目标账户
    allAccountIds.add(targetAccount.accountId);
    accountMap[targetAccount.accountId] = targetAccount;

    // 收集所有相关账户
    for (final assetFlow in flows) {
      allAccountIds.add(assetFlow.fromAccount.accountId);
      allAccountIds.add(assetFlow.toAccount.accountId);
      accountMap[assetFlow.fromAccount.accountId] = assetFlow.fromAccount;
      accountMap[assetFlow.toAccount.accountId] = assetFlow.toAccount;
    }

    // 获取所有父级账户
    await _loadParentAccounts(allAccountIds, accountMap);

    // 创建层级链接
    final hierarchicalLinks = _createHierarchicalLinks(
        flows, accountMap, targetAccount.accountId, flow);

    print('\n层级链接 (${hierarchicalLinks.length}条):');
    for (int i = 0; i < hierarchicalLinks.length; i++) {
      final link = hierarchicalLinks[i];
      final sourceName = accountMap[link.sourceId]?.accountName ?? 'Unknown';
      final targetName = accountMap[link.targetId]?.accountName ?? 'Unknown';
      print(
          '  ${i + 1}. $sourceName (${link.sourceId}) → $targetName (${link.targetId}): ¥${link.amount.toStringAsFixed(2)}');
    }

    // 聚合相同的链接和计算节点金额
    for (final link in hierarchicalLinks) {
      final linkKey = '${link.sourceId}->${link.targetId}';
      linkAmounts[linkKey] = (linkAmounts[linkKey] ?? 0) + link.amount;

      // 计算节点金额
      if (flow == 'in') {
        // 流入场景：源账户显示流出金额
        nodeAmounts[link.sourceId] =
            (nodeAmounts[link.sourceId] ?? 0) + link.amount;
      } else {
        // 流出场景：目标账户显示流入金额
        nodeAmounts[link.targetId] =
            (nodeAmounts[link.targetId] ?? 0) + link.amount;
      }
    }

    print('\n聚合后的链接:');
    linkAmounts.forEach((linkKey, amount) {
      final parts = linkKey.split('->');
      final sourceId = int.parse(parts[0]);
      final targetId = int.parse(parts[1]);
      final sourceName = accountMap[sourceId]?.accountName ?? 'Unknown';
      final targetName = accountMap[targetId]?.accountName ?? 'Unknown';
      print('  $sourceName → $targetName: ¥${amount.toStringAsFixed(2)}');
    });

    // 移除为账户设置余额的逻辑，只显示实际流转金额

    print('\n最终节点金额:');
    nodeAmounts.forEach((accountId, amount) {
      final accountName = accountMap[accountId]?.accountName ?? 'Unknown';
      print('  $accountName: ¥${amount.toStringAsFixed(2)}');
    });

    // 创建 SankeyNode 列表，只显示实际流转金额
    final nodes = accountMap.values.map((account) {
      final amount = nodeAmounts[account.accountId] ?? 0.0;

      // 账户名称只显示两个字
      String accountName = account.accountName;
      if (accountName.length > 2) {
        accountName = accountName.substring(0, 2);
      }

      // 目标账户不显示金额，其他账户显示实际流转金额
      String formattedAmount = '';
      if (account.accountId != targetAccount.accountId && amount > 0) {
        if (amount >= 1000000) {
          // 百万级，固定两位小数
          final millions = amount / 1000000;
          formattedAmount = ' (¥${millions.toStringAsFixed(2)}M)';
        } else if (amount >= 1000) {
          // 千级，固定两位小数
          final thousands = amount / 1000;
          formattedAmount = ' (¥${thousands.toStringAsFixed(2)}K)';
        } else {
          // 小额，固定两位小数
          formattedAmount = ' (¥${amount.toStringAsFixed(2)})';
        }
      }

      return SankeyNode(
        id: account.accountId,
        label: '$accountName$formattedAmount',
      );
    }).toList();

    // 创建节点ID到节点的映射
    final Map<int, SankeyNode> nodeMap = {
      for (final node in nodes) node.id: node
    };

    // 创建 SankeyLink 列表
    final links = <SankeyLink>[];
    linkAmounts.forEach((linkKey, amount) {
      final parts = linkKey.split('->');
      final sourceId = int.parse(parts[0]);
      final targetId = int.parse(parts[1]);

      final sourceNode = nodeMap[sourceId];
      final targetNode = nodeMap[targetId];

      if (sourceNode != null && targetNode != null) {
        links.add(SankeyLink(
          source: sourceNode,
          target: targetNode,
          value: amount,
        ));
      }
    });

    return SankeyChartData(
      nodes: nodes,
      links: links,
    );
  }

  Stream<List<AccountWithBalance>> watchTopLiabilityAccountsByLedger(
      {int? limit, required int ledgerId}) {
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((_) async {
      final accounts = await getTopLiabilityAccountsByLedger(
          ledgerId: ledgerId, limit: limit);
      return accounts;
    });
  }

  Stream<List<LiabilityHistoryData>> watchYearlyLiabilityHistory(
      {required int ledgerId}) {
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((_) => getYearlyLiabilityHistory(ledgerId: ledgerId));
  }

  Stream<List<LiabilityHistoryData>> watchLiabilityHistoryByTimeRange(
      DateTime start, DateTime end,
      {required int ledgerId, int? accountId}) {
    return _transactionDao.watchAllTransactions(ledgerId: ledgerId).asyncMap(
        (_) => getLiabilityHistoryByTimeRange(start, end,
            ledgerId: ledgerId, accountId: accountId));
  }

  Stream<List<account_ui.Account>> watchLiabilityAccountTree({int? ledgerId}) {
    if (ledgerId == null) {
      return Stream.value([]);
    }
    return _transactionDao
        .watchAllTransactions(ledgerId: ledgerId)
        .asyncMap((_) async {
      try {
        final accountTree = await getAccountTree(ledgerId: ledgerId);
        final liabilityAccounts = accountTree
            .where((acc) => acc.account.accountType == AccountType.LIABILITY)
            .toList();
        final result = await _convertAccountsToUIFormat(liabilityAccounts);
        return result;
      } catch (e) {
        print('[LiabilitiesRepository] Error in watchLiabilityAccountTree: $e');
        return [];
      }
    });
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
