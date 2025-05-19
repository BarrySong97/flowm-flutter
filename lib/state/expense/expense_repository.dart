import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/posting_dao.dart';
import '../../components/chart/barchart.dart' as barchart;
import '../database/database_provider.dart';
import '../../db/tables/account_table.dart';

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
      print('Debug: 查询参数');
      print('startDate: $startDate');
      print('endDate: $endDate');
      print('ledgerId: $ledgerId');
      print('accountId: $accountId');

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
      print('Debug: 支出账户数量: $expenseAccountCount');

      if (expenseAccountCount == 0) {
        print('Debug: 没有支出类型的账户');
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

      print('Debug: 查询结果数量: ${result.length}');

      // 将查询结果转换为ChartData列表
      final List<barchart.ChartData> chartData = [];
      int index = 0;

      for (final row in result) {
        try {
          final dateStr = row.read<String>('date');
          if (dateStr == null || dateStr.isEmpty) {
            print('Debug: 跳过空日期');
            continue;
          }

          final dateParts = dateStr.split('-');
          if (dateParts.length != 3) {
            print('Debug: 无效的日期格式: $dateStr');
            continue;
          }

          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );

          final amount = row.read<double>('total_expense');
          final count = row.read<int>('daily_count');

          print('Debug: 日期: $dateStr, 金额: $amount, 交易数: $count');

          final formattedDate = '${date.month}/${date.day}';
          chartData
              .add(barchart.ChartData(index.toDouble(), amount, formattedDate));
          index++;
        } catch (e) {
          print('处理行数据时出错: $e');
          print('Row data: ${row.data}');
          continue;
        }
      }

      return chartData;
    } catch (e) {
      print('获取支出图表数据时出错: $e');
      print('错误堆栈: ${e.toString()}');
      return [];
    }
  }
}
