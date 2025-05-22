import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/posting_dao.dart';
import '../../components/chart/barchart.dart' as barchart;
import '../database/database_provider.dart';
import '../../db/tables/account_table.dart';
import '../../models/account_expense_node.dart';

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
    print(
        '[IncomeRepository] getIncomeChartData called with: startDate: $startDate, endDate: $endDate, ledgerId: $ledgerId, accountId: $accountId');
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
      print(
          '[IncomeRepository] Found $incomeAccountCount income accounts for ledgerId: $ledgerId');

      if (incomeAccountCount == 0) {
        print(
            '[IncomeRepository] No income accounts found, returning empty list');
        return [];
      }

      print('[IncomeRepository] Executing SQL query to get daily income data');
      // 构建SQL查询，获取每日收入总额
      final result = await _postingDao.customSelect(
        '''
        WITH RECURSIVE DateRange(date) AS (
          SELECT date(?, 'unixepoch', 'localtime') as date
          UNION ALL
          SELECT date(date, '+1 day')
          FROM DateRange
          WHERE date < date(?, 'unixepoch', 'localtime')
        )
        SELECT 
          strftime('%Y-%m-%d', dr.date) as date,
          COALESCE(SUM(CASE 
            WHEN a.account_type = ? AND p.amount < 0 
            THEN ABS(p.amount) 
            ELSE 0 
          END), 0) as total_income,
          COUNT(DISTINCT CASE 
            WHEN a.account_type = ? AND p.amount < 0 
            THEN p.posting_id 
            ELSE NULL 
          END) as daily_count
        FROM DateRange dr
        LEFT JOIN transactions t ON date(t.transaction_date, 'unixepoch', 'localtime') = dr.date
        LEFT JOIN postings p ON p.transaction_id = t.transaction_id
        LEFT JOIN accounts a ON p.account_id = a.account_id 
          AND a.ledger_id = ? 
          ${accountId != null ? 'AND (a.account_id = ? OR a.parent_account_id = ?)' : ''}
        GROUP BY dr.date
        ORDER BY dr.date
        ''',
        variables: [
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          Variable.withString(AccountType.INCOME.name),
          Variable.withString(AccountType.INCOME.name),
          Variable.withInt(ledgerId),
          if (accountId != null) ...[
            Variable.withInt(accountId),
            Variable.withInt(accountId),
          ],
        ],
      ).get();

      print(
          '[IncomeRepository] SQL query completed. Retrieved ${result.length} rows');

      // 将查询结果转换为ChartData列表
      final List<barchart.ChartData> chartData = [];
      int index = 0;

      print('[IncomeRepository] Processing query results:');
      for (final row in result) {
        try {
          final dateStr = row.read<String>('date');
          final amount = row.read<double>('total_income');
          final count = row.read<int>('daily_count');

          print(
              '[IncomeRepository] Row data: date=$dateStr, amount=$amount, count=$count');

          if (dateStr == null || dateStr.isEmpty) {
            print('[IncomeRepository] Skipping row due to empty date string');
            continue;
          }

          final dateParts = dateStr.split('-');
          if (dateParts.length != 3) {
            print(
                '[IncomeRepository] Skipping row due to invalid date format: $dateStr');
            continue;
          }

          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );

          final formattedDate = '${date.month}/${date.day}';
          chartData
              .add(barchart.ChartData(index.toDouble(), amount, formattedDate));
          print(
              '[IncomeRepository] Added chart data: index=$index, amount=$amount, formattedDate=$formattedDate');
          index++;
        } catch (e) {
          print('[IncomeRepository] Error processing row: $e');
          continue;
        }
      }

      print(
          '[IncomeRepository] Returning ${chartData.length} chart data items');
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
    print(
        '[IncomeRepository] getIncomeAccountTree called with: startDate: $startDate, endDate: $endDate, ledgerId: $ledgerId');
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

      print(
          '[IncomeRepository] Fetched ${allIncomeAccounts.length} income accounts:');
      // for (final acc in allIncomeAccounts) {
      //   print('[IncomeRepository] Account: ${acc.toJson()}'); // toJson might be too verbose for Account data class
      // }

      if (allIncomeAccounts.isEmpty) {
        print(
            '[IncomeRepository] No income accounts found for ledgerId: $ledgerId.');
        return [];
      }

      final List<AccountExpenseNode> accountNodes = [];
      final Map<int, AccountExpenseNode> accountNodeMap = {};

      print('[IncomeRepository] Calculating direct income for each account...');
      for (final account in allIncomeAccounts) {
        final directIncomeResult = await _postingDao.customSelect(
          '''
          SELECT COALESCE(SUM(ABS(p.amount)), 0) as direct_balance
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id = ? 
            -- AND t.ledger_id = ? -- Removed: transactions table does not have ledger_id direct_balance
            AND t.transaction_date >= ? 
            AND t.transaction_date <= ?
            AND p.amount < 0; -- 假设收入记为负数，获取绝对值
          ''',
          variables: [
            Variable.withInt(account.accountId),
            // Variable.withInt(ledgerId), // Removed corresponding variable
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        ).getSingle();

        final directBalance = directIncomeResult.read<double>('direct_balance');
        print(
            '[IncomeRepository] Account: ${account.accountName} (ID: ${account.accountId}), Direct Balance: $directBalance');

        final node = AccountExpenseNode(
          accountData: account,
          balance: directBalance,
        );
        accountNodes.add(node);
        accountNodeMap[account.accountId] = node;
      }

      // 3. 构建树形结构并计算父节点余额
      print('[IncomeRepository] Building tree structure...');
      final List<AccountExpenseNode> rootNodes = [];
      for (final node in accountNodes) {
        if (node.accountData.parentAccountId != null &&
            accountNodeMap.containsKey(node.accountData.parentAccountId)) {
          accountNodeMap[node.accountData.parentAccountId!]!.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }
      print('[IncomeRepository] Found ${rootNodes.length} root nodes.');
      // for (final rNode in rootNodes) {
      //   print('[IncomeRepository] Root Node: ${rNode.toJson()}'); // toJson on node can be verbose
      // }

      // 4. 递归计算父节点的余额 和总收入
      print('[IncomeRepository] Calculating total balances for root nodes...');
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
      print(
          '[IncomeRepository] Calculated totalOverallIncome: $totalOverallIncome');

      // 5. 计算百分比
      if (totalOverallIncome > 0) {
        print('[IncomeRepository] Calculating percentages...');
        for (final node in accountNodes) {
          // 直接计算百分比，不进行任何四舍五入
          node.percentage = (node.balance / totalOverallIncome) * 100;
          print(
              '[IncomeRepository] Account: ${node.accountData.accountName}, Balance: ${node.balance}, Percentage: ${node.percentage}');
        }
      }

      print(
          '[IncomeRepository] getIncomeAccountTree returning ${rootNodes.length} root nodes.');
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
}
