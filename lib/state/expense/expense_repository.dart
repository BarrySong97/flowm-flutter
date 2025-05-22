import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/posting_dao.dart';
import '../../components/chart/barchart.dart' as barchart;
import '../database/database_provider.dart';
import '../../db/tables/account_table.dart';
import '../../models/account_expense_node.dart';

/// 支出仓库提供者
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return ExpenseRepository(postingDao);
});

/// 支出仓库类
class ExpenseRepository {
  final PostingDao _postingDao;

  ExpenseRepository(this._postingDao);

  /// 获取指定时间范围内的每日支出总额
  ///
  /// [startDate] 开始时间
  /// [endDate] 结束时间
  /// [ledgerId] 账本ID
  /// [accountId] 账户ID（可选）
  Future<List<barchart.ChartData>> getExpenseChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) async {
    try {
      // 首先检查是否有支出类型的账户
      final expenseAccounts = await _postingDao.customSelect(
        '''
        SELECT COUNT(*) as count
        FROM accounts
        WHERE ledger_id = ? AND account_type = ?
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.EXPENSE.name),
        ],
      ).getSingle();

      final expenseAccountCount = expenseAccounts.read<int>('count');

      if (expenseAccountCount == 0) {
        return [];
      }

      // 构建SQL查询，获取每日支出总额
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
            WHEN a.account_type = ? AND p.amount > 0 
            THEN p.amount 
            ELSE 0 
          END), 0) as total_expense,
          COUNT(DISTINCT CASE 
            WHEN a.account_type = ? AND p.amount > 0 
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
          Variable.withString(AccountType.EXPENSE.name),
          Variable.withString(AccountType.EXPENSE.name),
          Variable.withInt(ledgerId),
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

          final amount = row.read<double>('total_expense');
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

  /// 获取指定时间范围内的支出账户树形结构数据
  ///
  /// [startDate] 开始时间
  /// [endDate] 结束时间
  /// [ledgerId] 账本ID
  Future<List<AccountExpenseNode>> getExpenseAccountTree({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
  }) async {
    print(
        '[ExpenseRepository] getExpenseAccountTree called with: startDate: $startDate, endDate: $endDate, ledgerId: $ledgerId');
    try {
      // 1. 获取所有支出账户 (包括层级关系)
      final allExpenseAccountsQuery = _postingDao.customSelect(
        '''
        SELECT * 
        FROM accounts
        WHERE ledger_id = ? AND account_type = ?
        ORDER BY parent_account_id ASC, account_id ASC; 
        ''',
        variables: [
          Variable.withInt(ledgerId),
          Variable.withString(AccountType.EXPENSE.name),
        ],
      );
      final allExpenseAccountRows = await allExpenseAccountsQuery.get();
      final allExpenseAccounts = allExpenseAccountRows
          .map((row) => _postingDao.db.accounts.map(row.data))
          .toList();

      print(
          '[ExpenseRepository] Fetched ${allExpenseAccounts.length} expense accounts:');
      // for (final acc in allExpenseAccounts) {
      //   print('[ExpenseRepository] Account: ${acc.toJson()}'); // toJson might be too verbose for Account data class
      // }

      if (allExpenseAccounts.isEmpty) {
        print(
            '[ExpenseRepository] No expense accounts found for ledgerId: $ledgerId.');
        return [];
      }

      final List<AccountExpenseNode> accountNodes = [];
      final Map<int, AccountExpenseNode> accountNodeMap = {};

      print(
          '[ExpenseRepository] Calculating direct expenses for each account...');
      for (final account in allExpenseAccounts) {
        final directExpenseResult = await _postingDao.customSelect(
          '''
          SELECT COALESCE(SUM(p.amount), 0) as direct_balance
          FROM postings p
          JOIN transactions t ON p.transaction_id = t.transaction_id
          WHERE p.account_id = ? 
            -- AND t.ledger_id = ? -- Removed: transactions table does not have ledger_id direct_balance
            AND t.transaction_date >= ? 
            AND t.transaction_date <= ?
            AND p.amount > 0; -- 假设支出记为正数，或者根据您的分录设计调整
          ''',
          variables: [
            Variable.withInt(account.accountId),
            // Variable.withInt(ledgerId), // Removed corresponding variable
            Variable.withDateTime(startDate),
            Variable.withDateTime(endDate),
          ],
        ).getSingle();

        final directBalance =
            directExpenseResult.read<double>('direct_balance');
        print(
            '[ExpenseRepository] Account: ${account.accountName} (ID: ${account.accountId}), Direct Balance: $directBalance');

        final node = AccountExpenseNode(
          accountData: account,
          balance: directBalance,
        );
        accountNodes.add(node);
        accountNodeMap[account.accountId] = node;
      }

      // 3. 构建树形结构并计算父节点余额
      print('[ExpenseRepository] Building tree structure...');
      final List<AccountExpenseNode> rootNodes = [];
      for (final node in accountNodes) {
        if (node.accountData.parentAccountId != null &&
            accountNodeMap.containsKey(node.accountData.parentAccountId)) {
          accountNodeMap[node.accountData.parentAccountId!]!.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }
      print('[ExpenseRepository] Found ${rootNodes.length} root nodes.');
      // for (final rNode in rootNodes) {
      //   print('[ExpenseRepository] Root Node: ${rNode.toJson()}'); // toJson on node can be verbose
      // }

      // 4. 递归计算父节点的余额 和总支出
      print('[ExpenseRepository] Calculating total balances for root nodes...');
      double totalOverallExpense = 0;
      double updateTotalBalances(AccountExpenseNode node) {
        double childrenBalance = 0;
        for (final child in node.children) {
          childrenBalance += updateTotalBalances(child);
        }
        node.balance += childrenBalance;
        return node.balance;
      }

      for (final rootNode in rootNodes) {
        totalOverallExpense += updateTotalBalances(rootNode);
      }
      print(
          '[ExpenseRepository] Calculated totalOverallExpense: $totalOverallExpense');

      // 5. 计算百分比
      if (totalOverallExpense > 0) {
        print('[ExpenseRepository] Calculating percentages...');
        for (final node in accountNodes) {
          node.percentage = (node.balance / totalOverallExpense) * 100;
        }
      }

      print(
          '[ExpenseRepository] getExpenseAccountTree returning ${rootNodes.length} root nodes.');
      // rootNodes.forEach((node) => print('[ExpenseRepository] Final Root Node: ${node.toJson()}'));
      return rootNodes;
    } catch (e, s) {
      print('[ExpenseRepository] Error in getExpenseAccountTree: $e');
      print('[ExpenseRepository] Stacktrace: $s');
      return [];
    }
  }
}
