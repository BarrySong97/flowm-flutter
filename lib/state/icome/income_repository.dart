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
      // 首先检查是否有收入类型的账户
      final incomeAccounts = await _postingDao.customSelect(
        '''
        SELECT COUNT(*) as count
        FROM accounts
        WHERE ledger_id = ? AND account_type = ?
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.INCOME.name),
        ],
      ).getSingle();

      final incomeAccountCount = incomeAccounts.read<int>('count');

      if (incomeAccountCount == 0) {
        return [];
      }

      // 优化后的SQL查询
      // 1. 使用 CTE (DailyIncomes) 预先聚合每日的收入数据，对 transaction_date 使用范围查询以利用索引。
      // 2. 保持 DateRange CTE 来生成完整的日期序列。
      // 3. 将 DateRange 与聚合后的 DailyIncomes 进行 LEFT JOIN，以填充没有收入的日期。
      final result = await _postingDao.customSelect(
        '''
        WITH RECURSIVE DateRange(date) AS (
          SELECT date(?, 'unixepoch', 'localtime')
          UNION ALL
          SELECT date(date, '+1 day')
          FROM DateRange
          WHERE date <= date(?, 'unixepoch', 'localtime')
        ),
        DailyIncomes AS (
          SELECT
            date(t.transaction_date, 'unixepoch', 'localtime') as income_date,
            -SUM(p.amount) as total_income,
            COUNT(p.posting_id) as daily_count
          FROM transactions t
          JOIN postings p ON p.transaction_id = t.transaction_id
          JOIN accounts a ON p.account_id = a.account_id
          WHERE t.transaction_date BETWEEN ? AND ?
            AND a.ledger_id = ?
            AND a.account_type = ?
            AND p.amount < 0
            ${accountId != null ? 'AND (a.account_id = ? OR a.parent_account_id = ?)' : ''}
          GROUP BY income_date
        )
        SELECT 
          strftime('%Y-%m-%d', dr.date) as date,
          COALESCE(di.total_income, 0) as total_income,
          COALESCE(di.daily_count, 0) as daily_count
        FROM DateRange dr
        LEFT JOIN DailyIncomes di ON di.income_date = dr.date
        ORDER BY dr.date;
        ''',
        variables: [
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          Variable.withDateTime(
              DateTime(startDate.year, startDate.month, startDate.day)),
          Variable.withDateTime(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)),
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.INCOME.name),
          if (accountId != null) ...[
            Variable.withInt(accountId),
            Variable.withInt(accountId),
          ],
        ],
      ).get();

      // 将查询结果转换为ChartData列表
      final List<barchart.ChartData> chartData = [];
      int index = 0;

      for (final row in result) {
        try {
          final dateStr = row.read<String>('date');
          if (dateStr == null || dateStr.isEmpty) {
            continue;
          }

          final dateParts = dateStr.split('-');
          if (dateParts.length != 3) {
            continue;
          }

          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );

          final amount = row.read<double>('total_income');
          final count = row.read<int>('daily_count');

          final formattedDate = '${date.month}/${date.day}';
          chartData
              .add(barchart.ChartData(index.toDouble(), amount, formattedDate));
          index++;
        } catch (e) {
          continue;
        }
      }

      return chartData;
    } catch (e) {
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
    print(
        '[IncomeRepository] getIncomeAccountTree called with: startDate: $startDate, endDate: $endDate, ledgerId: $ledgerId');
    try {
      // 1. 获取所有收入账户 (包括层级关系)
      final allIncomeAccountRows = await _postingDao.customSelect(
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
      ).get();
      final allIncomeAccounts = allIncomeAccountRows
          .map((row) => _postingDao.db.accounts.map(row.data))
          .toList();

      if (allIncomeAccounts.isEmpty) {
        return [];
      }

      // 2. 优化：一次性获取所有相关账户在时间范围内的收入总额
      final incomeSumsRows = await _postingDao.customSelect(
        '''
        SELECT 
          p.account_id, 
          -SUM(p.amount) as direct_balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        JOIN accounts a ON p.account_id = a.account_id
        WHERE t.transaction_date BETWEEN ? AND ?
          AND a.ledger_id = ?
          AND a.account_type = ?
          AND p.amount < 0
        GROUP BY p.account_id;
        ''',
        variables: [
          Variable.withDateTime(
              DateTime(startDate.year, startDate.month, startDate.day)),
          Variable.withDateTime(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)),
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.INCOME.name),
        ],
      ).get();

      final Map<int, double> accountBalances = {
        for (var row in incomeSumsRows)
          row.read<int>('account_id'): row.read<double>('direct_balance')
      };

      final List<AccountExpenseNode> accountNodes = [];
      final Map<int, AccountExpenseNode> accountNodeMap = {};

      // 3. 构建节点，从Map中获取余额，避免N+1查询
      for (final account in allIncomeAccounts) {
        final directBalance = accountBalances[account.accountId] ?? 0.0;

        final node = AccountExpenseNode(
          accountData: account,
          balance: directBalance,
        );
        accountNodes.add(node);
        accountNodeMap[account.accountId] = node;
      }

      // 4. 构建树形结构并计算父节点余额
      final List<AccountExpenseNode> rootNodes = [];
      for (final node in accountNodes) {
        if (node.accountData.parentAccountId != null &&
            accountNodeMap.containsKey(node.accountData.parentAccountId)) {
          accountNodeMap[node.accountData.parentAccountId!]!.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }

      // 5. 递归计算父节点的余额 和总收入
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

      // 6. 计算百分比
      if (totalOverallIncome > 0) {
        for (final node in accountNodes) {
          node.percentage = (node.balance / totalOverallIncome) * 100;
        }
      }

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
          COALESCE(-SUM(p.amount), 0) as total_balance
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
          COALESCE(-SUM(p.amount), 0) as total_balance
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
