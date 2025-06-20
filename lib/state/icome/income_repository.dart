import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/posting_dao.dart';
import '../../components/chart/barchart.dart' as barchart;
import '../database/database_provider.dart';
import '../../db/tables/account_table.dart';
import '../../models/account_expense_node.dart';
import '../../components/common/time_range_selector.dart';
import '../../db/dao/transaction_dao.dart';

/// 收入仓库提供者
final IncomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return IncomeRepository(postingDao);
});

/// 收入仓库类
class IncomeRepository {
  final PostingDao _postingDao;

  IncomeRepository(this._postingDao);

  /// 获取指定时间范围内的每日收入总额
  ///
  /// [startDate] 开始时间
  /// [endDate] 结束时间
  /// [ledgerId] 账本ID
  /// [accountId] 账户ID（可选）
  Future<List<barchart.ChartData>> getIncomeChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) async {
    try {
      final incomeAccounts = await _postingDao.customSelect(
        'SELECT 1 FROM accounts WHERE ledger_id = ? AND account_type = ? LIMIT 1',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.INCOME.name),
        ],
      ).getSingleOrNull();

      if (incomeAccounts == null) {
        return [];
      }

      // 调整endDate以包含一整天
      final inclusiveEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final query = '''
        SELECT
          strftime('%Y-%m-%d', t.transaction_date, 'unixepoch', 'localtime') as date_str,
          SUM(ABS(p.amount)) as total_income
        FROM transactions t
        JOIN postings p ON p.transaction_id = t.transaction_id
        JOIN accounts a ON p.account_id = a.account_id
        WHERE t.transaction_date BETWEEN ? AND ?
          AND a.ledger_id = ?
          AND a.account_type = ?
          AND p.amount < 0
          ${accountId != null ? 'AND (a.account_id = ? OR a.parent_account_id = ?)' : ''}
        GROUP BY date_str
        ORDER BY date_str;
      ''';

      final variables = [
        Variable.withDateTime(startDate),
        Variable.withDateTime(inclusiveEndDate),
        Variable.withInt(ledgerId),
        Variable.withString(AccountType.INCOME.name),
        if (accountId != null) ...[
          Variable.withInt(accountId),
          Variable.withInt(accountId),
        ],
      ];

      final result =
          await _postingDao.customSelect(query, variables: variables).get();

      final Map<String, double> incomeByDate = {
        for (var row in result)
          row.read<String>('date_str'): row.read<double>('total_income'),
      };

      final List<barchart.ChartData> chartData = [];
      int index = 0;
      for (var day = 0; day <= endDate.difference(startDate).inDays; day++) {
        final currentDate = startDate.add(Duration(days: day));
        final dateStr =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        final amount = incomeByDate[dateStr] ?? 0.0;
        final formattedDate = '${currentDate.month}/${currentDate.day}';

        chartData
            .add(barchart.ChartData(index.toDouble(), amount, formattedDate));
        index++;
      }

      return chartData;
    } catch (e, s) {
      print('[IncomeRepository] Error in getIncomeChartData: $e');
      print('[IncomeRepository] Stacktrace: $s');
      return [];
    }
  }

  /// 获取指定时间范围内的收入账户树形结构数据
  ///
  /// [startDate] 开始时间
  /// [endDate] 结束时间
  /// [ledgerId] 账本ID
  Future<List<AccountExpenseNode>> getIncomeAccountTree({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
  }) async {
    try {
      // 1. 获取所有收入账户 (包括层级关系)
      final allIncomeAccountsQuery = _postingDao.customSelect(
        '''
        SELECT * 
        FROM accounts
        WHERE ledger_id = ? AND account_type = ?
        ORDER BY parent_account_id ASC, account_id ASC; 
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.INCOME.name),
        ],
      );
      final allIncomeAccountRows = await allIncomeAccountsQuery.get();
      final allIncomeAccounts = allIncomeAccountRows
          .map((row) => _postingDao.db.accounts.map(row.data))
          .toList();

      if (allIncomeAccounts.isEmpty) {
        return [];
      }

      // 2. 一次性查询所有账户的直接收入余额
      final accountIds = allIncomeAccounts.map((a) => a.accountId).toList();
      final placeholders = accountIds.map((id) => '?').join(',');

      final directIncomesQuery = _postingDao.customSelect(
        '''
        SELECT 
          p.account_id,
          COALESCE(SUM(ABS(p.amount)), 0) as direct_balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        WHERE p.account_id IN ($placeholders)
          AND t.transaction_date >= ? 
          AND t.transaction_date <= ?
          AND p.amount < 0
        GROUP BY p.account_id;
        ''',
        variables: [
          ...accountIds.map((id) => Variable.withInt(id)),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      );

      final directIncomesResult = await directIncomesQuery.get();
      final Map<int, double> directIncomesMap = {
        for (var row in directIncomesResult)
          row.read<int>('account_id'): row.read<double>('direct_balance'),
      };

      final List<AccountExpenseNode> accountNodes = [];
      final Map<int, AccountExpenseNode> accountNodeMap = {};

      for (final account in allIncomeAccounts) {
        final directBalance = directIncomesMap[account.accountId] ?? 0.0;

        final node = AccountExpenseNode(
          accountData: account,
          balance: directBalance,
        );
        accountNodes.add(node);
        accountNodeMap[account.accountId] = node;
      }

      // 3. 构建树形结构并计算父节点余额

      final List<AccountExpenseNode> rootNodes = [];
      for (final node in accountNodes) {
        if (node.accountData.parentAccountId != null &&
            accountNodeMap.containsKey(node.accountData.parentAccountId)) {
          accountNodeMap[node.accountData.parentAccountId!]!.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }

      // 4. 递归计算父节点的余额 和总收入
      double totalOverallIncome = 0;
      double updateTotalBalances(AccountExpenseNode node) {
        double childrenBalance = 0;
        for (final child in node.children) {
          childrenBalance += updateTotalBalances(child);
        }
        node.balance += childrenBalance;
        return node.balance;
      }

      for (final rootNode in rootNodes) {
        totalOverallIncome += updateTotalBalances(rootNode);
      }

      // 5. 计算百分比
      if (totalOverallIncome > 0) {
        for (final node in accountNodes) {
          // 直接计算百分比，不进行任何四舍五入
          node.percentage = (node.balance / totalOverallIncome) * 100;
        }
      }

      // rootNodes.forEach((node) => print('[IncomeRepository] Final Root Node: ${node.toJson()}'));
      return rootNodes;
    } catch (e, s) {
      print('[IncomeRepository] Error in getIncomeAccountTree: $e');
      print('[IncomeRepository] Stacktrace: $s');
      return [];
    }
  }

  /// 获取指定账户及其子账户在特定时间范围内的总收入余额
  ///
  /// [accountId] 要查询的收入账户ID
  /// [startDate] 开始时间
  /// [endDate] 结束时间
  Future<double> getAccountIncomeBalance({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await _postingDao.customSelect(
        '''
        SELECT 
          COALESCE(SUM(ABS(p.amount)), 0) as total_balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        JOIN accounts a ON p.account_id = a.account_id
        WHERE p.account_id = ? 
          AND a.account_type = ? 
          AND t.transaction_date >= ? 
          AND t.transaction_date <= ?
          AND p.amount < 0; -- 获取负值收入的绝对值
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withString(AccountType.INCOME.name),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      ).getSingle();

      return result.read<double>('total_balance');
    } catch (e, s) {
      print('[IncomeRepository] Error in getAccountIncomeBalance: $e');
      print('[IncomeRepository] Stacktrace: $s');
      return 0.0;
    }
  }

  /// 获取指定账户的总收入余额（不区分时间）
  ///
  /// [accountId] 要查询的收入账户ID
  Future<double> getAccountIncomeTotalBalance({
    required int accountId,
  }) async {
    try {
      final result = await _postingDao.customSelect(
        '''
        SELECT 
          COALESCE(SUM(ABS(p.amount)), 0) as total_balance
        FROM postings p
        JOIN accounts a ON p.account_id = a.account_id
        WHERE p.account_id = ? 
          AND a.account_type = ? 
          AND p.amount < 0; -- 获取负值收入的绝对值
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withString(AccountType.INCOME.name),
        ],
      ).getSingle();

      return result.read<double>('total_balance');
    } catch (e, s) {
      print('[IncomeRepository] Error in getAccountIncomeTotalBalance: $e');
      print('[IncomeRepository] Stacktrace: $s');
      return 0.0;
    }
  }

  /// 监听指定账户在指定时间范围内的交易记录
  Stream<List<TransactionWithAmount>> watchAccountTransactions({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _postingDao.db.transactionDao.watchTransactionsByAccountAndDateRange(
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

  /// 根据TimeRange获取结束日期
  DateTime _getEndDateFromTimeRange(TimeRange timeRange) {
    return DateTime.now();
  }
}

/// 监听账户交易的Provider
final accountIncomeTransactionsProvider = StreamProvider.family<
    List<TransactionWithAmount>,
    ({int accountId, DateTime startDate, DateTime endDate})>((ref, params) {
  final incomeRepository = ref.watch(IncomeRepositoryProvider);
  return incomeRepository.watchAccountTransactions(
    accountId: params.accountId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
