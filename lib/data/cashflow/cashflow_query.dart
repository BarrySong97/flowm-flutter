import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/db/dao/posting_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/domain/finance/finance_types.dart';
import 'package:flowm/models/account_expense_node.dart';

class CashflowQuery {
  const CashflowQuery(this._postingDao);

  final PostingDao _postingDao;

  Future<List<barchart.ChartData>> getChartData({
    required CashflowType type,
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) async {
    switch (type) {
      case CashflowType.expense:
        return _getExpenseChartData(
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
          accountId: accountId,
        );
      case CashflowType.income:
        return _getIncomeChartData(
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
          accountId: accountId,
        );
    }
  }

  Future<List<AccountExpenseNode>> getAccountTree({
    required CashflowType type,
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
  }) async {
    switch (type) {
      case CashflowType.expense:
        return _getAccountTree(
          accountType: AccountType.EXPENSE,
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
          amountExpression: 'SUM(p.amount)',
          amountFilter: '',
          logPrefix: 'ExpenseRepository',
        );
      case CashflowType.income:
        return _getAccountTree(
          accountType: AccountType.INCOME,
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
          amountExpression: '-SUM(p.amount)',
          amountFilter: 'AND p.amount < 0',
          logPrefix: 'IncomeRepository',
        );
    }
  }

  Future<double> getAccountBalance({
    required CashflowType type,
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    switch (type) {
      case CashflowType.expense:
        return _getAccountBalance(
          accountType: AccountType.EXPENSE,
          accountId: accountId,
          startDate: startDate,
          endDate: endDate,
          amountExpression: 'SUM(p.amount)',
          amountFilter: '',
          logPrefix: 'ExpenseRepository',
        );
      case CashflowType.income:
        return _getAccountBalance(
          accountType: AccountType.INCOME,
          accountId: accountId,
          startDate: startDate,
          endDate: endDate,
          amountExpression: '-SUM(p.amount)',
          amountFilter: 'AND p.amount < 0',
          logPrefix: 'IncomeRepository',
        );
    }
  }

  Future<double> getAccountTotalBalance({
    required CashflowType type,
    required int accountId,
  }) async {
    switch (type) {
      case CashflowType.expense:
        return _getAccountTotalBalance(
          accountType: AccountType.EXPENSE,
          accountId: accountId,
          amountExpression: 'SUM(p.amount)',
          amountFilter: '',
          logPrefix: 'ExpenseRepository',
        );
      case CashflowType.income:
        return _getAccountTotalBalance(
          accountType: AccountType.INCOME,
          accountId: accountId,
          amountExpression: '-SUM(p.amount)',
          amountFilter: 'AND p.amount < 0',
          logPrefix: 'IncomeRepository',
        );
    }
  }

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

  Future<List<barchart.ChartData>> _getExpenseChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) async {
    try {
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

      if (expenseAccounts.read<int>('count') == 0) {
        return [];
      }

      final result = await _postingDao.customSelect(
        '''
        WITH RECURSIVE DateRange(date) AS (
          SELECT date(?, 'unixepoch', 'localtime')
          UNION ALL
          SELECT date(date, '+1 day')
          FROM DateRange
          WHERE date < date(?, 'unixepoch', 'localtime')
        ),
        DailyExpenses AS (
          SELECT
            date(t.transaction_date, 'unixepoch', 'localtime') as expense_date,
            SUM(
              CASE
                WHEN a.account_type = 'EXPENSE' THEN p.amount
                WHEN a.account_type = 'LIABILITY' AND p.amount > 0 THEN p.amount
                ELSE 0
              END
            ) as total_expense,
            COUNT(p.posting_id) as daily_count
          FROM transactions t
          JOIN postings p ON p.transaction_id = t.transaction_id
          JOIN accounts a ON p.account_id = a.account_id
          WHERE t.transaction_date BETWEEN ? AND ?
            AND a.ledger_id = ?
            AND (
              (a.account_type = 'EXPENSE') OR
              (a.account_type = 'LIABILITY' AND p.amount > 0)
            )
            ${accountId != null ? 'AND (a.account_id = ? OR a.parent_account_id = ?)' : ''}
          GROUP BY expense_date
        )
        SELECT
          strftime('%Y-%m-%d', dr.date) as date,
          COALESCE(de.total_expense, 0) as amount,
          COALESCE(de.daily_count, 0) as daily_count
        FROM DateRange dr
        LEFT JOIN DailyExpenses de ON de.expense_date = dr.date
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
          if (accountId != null) ...[
            Variable.withInt(accountId),
            Variable.withInt(accountId),
          ],
        ],
      ).get();

      return _mapChartRows(result);
    } catch (e) {
      return [];
    }
  }

  Future<List<barchart.ChartData>> _getIncomeChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) async {
    try {
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

      if (incomeAccounts.read<int>('count') == 0) {
        return [];
      }

      final result = await _postingDao.customSelect(
        '''
        WITH RECURSIVE DateRange(date) AS (
          SELECT date(?, 'unixepoch', 'localtime')
          UNION ALL
          SELECT date(date, '+1 day')
          FROM DateRange
          WHERE date < date(?, 'unixepoch', 'localtime')
        ),
        DailyIncomes AS (
          SELECT
            date(t.transaction_date, 'unixepoch', 'localtime') as income_date,
            -SUM(p.amount) as amount,
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
          COALESCE(di.amount, 0) as amount,
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

      return _mapChartRows(result);
    } catch (e) {
      return [];
    }
  }

  List<barchart.ChartData> _mapChartRows(List<QueryRow> rows) {
    final chartData = <barchart.ChartData>[];
    var index = 0;

    for (final row in rows) {
      try {
        final dateStr = row.read<String>('date');
        if (dateStr.isEmpty) {
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
        final amount = row.read<double>('amount');
        final formattedDate = '${date.month}/${date.day}';
        chartData
            .add(barchart.ChartData(index.toDouble(), amount, formattedDate));
        index++;
      } catch (e) {
        continue;
      }
    }

    return chartData;
  }

  Future<List<AccountExpenseNode>> _getAccountTree({
    required AccountType accountType,
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    required String amountExpression,
    required String amountFilter,
    required String logPrefix,
  }) async {
    try {
      final allAccounts = await (_postingDao.db.select(_postingDao.db.accounts)
            ..where((a) => a.ledgerId.equals(ledgerId))
            ..where((a) => a.accountType.equals(accountType.name))
            ..orderBy([
              (a) => OrderingTerm(expression: a.parentAccountId),
              (a) => OrderingTerm(expression: a.accountId),
            ]))
          .get();

      final sumRows = await _postingDao.customSelect(
        '''
        SELECT
          p.account_id,
          COALESCE($amountExpression, 0) as direct_balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        JOIN accounts a ON p.account_id = a.account_id
        WHERE t.transaction_date BETWEEN ? AND ?
          AND a.ledger_id = ?
          AND a.account_type = ?
          $amountFilter
        GROUP BY p.account_id;
        ''',
        variables: [
          Variable.withDateTime(
              DateTime(startDate.year, startDate.month, startDate.day)),
          Variable.withDateTime(
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)),
          Variable.withInt(ledgerId),
          Variable.withString(accountType.name),
        ],
      ).get();

      final accountBalances = {
        for (final row in sumRows)
          row.read<int>('account_id'): row.read<double>('direct_balance')
      };

      final accountNodes = <AccountExpenseNode>[];
      final accountNodeMap = <int, AccountExpenseNode>{};

      for (final account in allAccounts) {
        final node = AccountExpenseNode(
          accountData: account,
          balance: accountBalances[account.accountId] ?? 0.0,
        );
        accountNodes.add(node);
        accountNodeMap[account.accountId] = node;
      }

      final rootNodes = <AccountExpenseNode>[];
      for (final node in accountNodes) {
        if (node.accountData.parentAccountId != null &&
            accountNodeMap.containsKey(node.accountData.parentAccountId)) {
          accountNodeMap[node.accountData.parentAccountId!]!.children.add(node);
        } else {
          rootNodes.add(node);
        }
      }

      var totalOverall = 0.0;
      double updateTotalBalances(AccountExpenseNode node) {
        var childrenBalance = 0.0;
        for (final child in node.children) {
          childrenBalance += updateTotalBalances(child);
        }
        node.balance += childrenBalance;
        return node.balance;
      }

      for (final rootNode in rootNodes) {
        totalOverall += updateTotalBalances(rootNode);
      }

      if (totalOverall > 0) {
        for (final node in accountNodes) {
          node.percentage = (node.balance / totalOverall) * 100;
        }
      }

      return rootNodes;
    } catch (e, s) {
      debugPrint('[$logPrefix] Error in get${accountType.name}AccountTree: $e');
      debugPrint('[$logPrefix] Stacktrace: $s');
      return [];
    }
  }

  Future<double> _getAccountBalance({
    required AccountType accountType,
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    required String amountExpression,
    required String amountFilter,
    required String logPrefix,
  }) async {
    try {
      final result = await _postingDao.customSelect(
        '''
        SELECT
          COALESCE($amountExpression, 0) as total_balance
        FROM postings p
        JOIN transactions t ON p.transaction_id = t.transaction_id
        JOIN accounts a ON p.account_id = a.account_id
        WHERE p.account_id = ?
          AND a.account_type = ?
          AND t.transaction_date >= ?
          AND t.transaction_date <= ?
          $amountFilter;
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withString(accountType.name),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      ).getSingle();

      return result.read<double>('total_balance');
    } catch (e, s) {
      debugPrint(
          '[$logPrefix] Error in getAccount${accountType.name}Balance: $e');
      debugPrint('[$logPrefix] Stacktrace: $s');
      return 0.0;
    }
  }

  Future<double> _getAccountTotalBalance({
    required AccountType accountType,
    required int accountId,
    required String amountExpression,
    required String amountFilter,
    required String logPrefix,
  }) async {
    try {
      final result = await _postingDao.customSelect(
        '''
        SELECT
          COALESCE($amountExpression, 0) as total_balance
        FROM postings p
        JOIN accounts a ON p.account_id = a.account_id
        WHERE p.account_id = ?
          AND a.account_type = ?
          $amountFilter;
        ''',
        variables: [
          Variable.withInt(accountId),
          Variable.withString(accountType.name),
        ],
      ).getSingle();

      return result.read<double>('total_balance');
    } catch (e, s) {
      debugPrint(
          '[$logPrefix] Error in getAccount${accountType.name}TotalBalance: $e');
      debugPrint('[$logPrefix] Stacktrace: $s');
      return 0.0;
    }
  }
}
