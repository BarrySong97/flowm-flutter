import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_table.dart';
import '../tables/posting_table.dart';
import '../tables/account_table.dart';
import '../../utils/transaction_type_map.dart';

part 'transaction_dao.g.dart';

// Define a class to hold transaction with its total amount
class TransactionWithAmount {
  final Transaction transaction;
  final double amount;
  final Account? fromAccount;
  final Account? toAccount;
  final TransactionNature nature;

  TransactionWithAmount({
    required this.transaction,
    required this.amount,
    this.fromAccount,
    this.toAccount,
    required this.nature,
  });
}

@DriftAccessor(tables: [Transactions, Postings, Accounts])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(AppDatabase db) : super(db);

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();

  // Get transaction by ID
  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.transactionId.equals(id)))
          .getSingleOrNull();

  // Watch all transactions (reactive stream)
  Stream<List<Transaction>> watchAllTransactions() =>
      select(transactions).watch();

  // Watch transactions by date range
  Stream<List<Transaction>> watchTransactionsByDateRange(
          DateTime startDate, DateTime endDate) =>
      (select(transactions)
            ..where(
                (t) => t.transactionDate.isBetweenValues(startDate, endDate))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.transactionDate, mode: OrderingMode.desc)
            ]))
          .watch();

  // Watch latest transactions
  Stream<List<TransactionWithAmount>> watchLatestTransactions(
      {int limit = 10}) {
    // Step 1: Get the latest transaction models as a stream.
    final latestTransactionsQuery = select(transactions)
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.transactionDate, mode: OrderingMode.desc),
        (t) =>
            OrderingTerm(expression: t.transactionId, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return latestTransactionsQuery
        .watch()
        .asyncMap((latestTransactionsList) async {
      if (latestTransactionsList.isEmpty) {
        return <TransactionWithAmount>[];
      }

      final resultList = <TransactionWithAmount>[];

      for (final transaction in latestTransactionsList) {
        // Step 2: For each transaction, get its postings and their account objects
        final postingsQuery = select(db.postings).join([
          innerJoin(db.accounts,
              db.accounts.accountId.equalsExp(db.postings.accountId)),
        ])
          ..where(db.postings.transactionId.equals(transaction.transactionId));

        final postingsWithAccounts = await postingsQuery.get();

        Account? fromAccountObj;
        Account? toAccountObj;
        double transactionAmount = 0;

        if (postingsWithAccounts.isNotEmpty) {
          final firstPosting =
              postingsWithAccounts.first.readTable(db.postings);
          transactionAmount = firstPosting.amount.abs();
        }

        for (final rowData in postingsWithAccounts) {
          final posting = rowData.readTable(db.postings);
          final account = rowData.readTable(db.accounts);
          if (posting.amount < 0) {
            fromAccountObj = account;
          } else if (posting.amount > 0) {
            toAccountObj = account;
          }
        }

        // Determine transaction nature
        final nature = getTransactionNature(
            fromAccountObj?.accountType, toAccountObj?.accountType);

        resultList.add(TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccountObj,
          toAccount: toAccountObj,
          nature: nature,
        ));
      }
      return resultList;
    });
  }

  // Watch transactions with amount and pagination
  Stream<List<TransactionWithAmount>> watchTransactionsWithAmountPaginated(
      {required int limit, required int offset}) {
    final paginatedTransactionsQuery = select(transactions)
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.transactionDate, mode: OrderingMode.desc),
        (t) =>
            OrderingTerm(expression: t.transactionId, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return paginatedTransactionsQuery
        .watch()
        .asyncMap((paginatedTransactionsList) async {
      if (paginatedTransactionsList.isEmpty) {
        return <TransactionWithAmount>[];
      }

      final resultList = <TransactionWithAmount>[];

      for (final transaction in paginatedTransactionsList) {
        final postingsQuery = select(db.postings).join([
          innerJoin(db.accounts,
              db.accounts.accountId.equalsExp(db.postings.accountId)),
        ])
          ..where(db.postings.transactionId.equals(transaction.transactionId));

        final postingsWithAccounts = await postingsQuery.get();

        Account? fromAccountObj;
        Account? toAccountObj;
        double transactionAmount = 0;

        if (postingsWithAccounts.isNotEmpty) {
          final firstPosting =
              postingsWithAccounts.first.readTable(db.postings);
          transactionAmount = firstPosting.amount.abs();
        }

        for (final rowData in postingsWithAccounts) {
          final posting = rowData.readTable(db.postings);
          final account = rowData.readTable(db.accounts);
          if (posting.amount < 0) {
            fromAccountObj = account;
          } else if (posting.amount > 0) {
            toAccountObj = account;
          }
        }

        // Determine transaction nature
        final nature = getTransactionNature(
            fromAccountObj?.accountType, toAccountObj?.accountType);

        resultList.add(TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccountObj,
          toAccount: toAccountObj,
          nature: nature,
        ));
      }
      return resultList;
    });
  }

  // Watch transactions with amount by day
  Stream<List<TransactionWithAmount>> watchTransactionsWithAmountByDay(
      DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

    final dayTransactionsQuery = select(transactions)
      ..where((t) => t.transactionDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.transactionDate, mode: OrderingMode.desc),
        (t) =>
            OrderingTerm(expression: t.transactionId, mode: OrderingMode.desc),
      ]);

    return dayTransactionsQuery.watch().asyncMap((dailyTransactionsList) async {
      if (dailyTransactionsList.isEmpty) {
        return <TransactionWithAmount>[];
      }

      final resultList = <TransactionWithAmount>[];

      for (final transaction in dailyTransactionsList) {
        final postingsQuery = select(db.postings).join([
          innerJoin(db.accounts,
              db.accounts.accountId.equalsExp(db.postings.accountId)),
        ])
          ..where(db.postings.transactionId.equals(transaction.transactionId));

        final postingsWithAccounts = await postingsQuery.get();

        Account? fromAccountObj;
        Account? toAccountObj;
        double transactionAmount = 0;

        if (postingsWithAccounts.isNotEmpty) {
          final firstPosting =
              postingsWithAccounts.first.readTable(db.postings);
          // The amount in TransactionWithAmount is typically the "principal" amount of the transaction, often positive.
          // The nature (income/expense/transfer) defines its effect.
          transactionAmount = firstPosting.amount.abs();
        }

        for (final rowData in postingsWithAccounts) {
          final posting = rowData.readTable(db.postings);
          final account = rowData.readTable(db.accounts);
          // This logic assumes a simple two-posting transaction (debit/credit)
          // For more complex splits, this might need adjustment or rely on how 'nature' is determined
          if (posting.amount < 0) {
            fromAccountObj = account;
          } else if (posting.amount > 0) {
            toAccountObj = account;
          }
        }

        // Determine transaction nature
        final nature = getTransactionNature(
            fromAccountObj?.accountType, toAccountObj?.accountType);

        resultList.add(TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccountObj,
          toAccount: toAccountObj,
          nature: nature,
        ));
      }
      return resultList;
    });
  }

  // Watch latest transactions filtered by account IDs
  Stream<List<TransactionWithAmount>> watchLatestTransactionsByAccountIds(
      {required Set<int> accountIds, int limit = 10}) {
    // 如果没有账户ID，直接返回空列表
    if (accountIds.isEmpty) {
      return Stream.value([]);
    }

    // 首先找出与指定账户相关的交易ID
    return customSelect(
      '''
      SELECT DISTINCT t.transaction_id 
      FROM transactions t
      JOIN postings p ON t.transaction_id = p.transaction_id
      WHERE p.account_id IN (${List.filled(accountIds.length, '?').join(',')})
      ORDER BY t.transaction_date DESC, t.transaction_id DESC
      LIMIT ?
      ''',
      variables: [
        ...accountIds.map((id) => Variable.withInt(id)),
        Variable.withInt(limit),
      ],
    ).watch().asyncMap((rows) async {
      if (rows.isEmpty) {
        return <TransactionWithAmount>[];
      }

      // 提取交易ID
      final transactionIds =
          rows.map((row) => row.read<int>('transaction_id')).toList();

      // 创建结果列表
      final resultList = <TransactionWithAmount>[];

      // 获取每个交易的详细信息
      for (final transactionId in transactionIds) {
        // 获取交易记录
        final transaction = await (select(transactions)
              ..where((t) => t.transactionId.equals(transactionId)))
            .getSingle();

        // 获取与该交易相关的postings和账户信息
        final postingsQuery = select(db.postings).join([
          innerJoin(db.accounts,
              db.accounts.accountId.equalsExp(db.postings.accountId)),
        ])
          ..where(db.postings.transactionId.equals(transactionId));

        final postingsWithAccounts = await postingsQuery.get();

        Account? fromAccountObj;
        Account? toAccountObj;
        double transactionAmount = 0;

        if (postingsWithAccounts.isNotEmpty) {
          final firstPosting =
              postingsWithAccounts.first.readTable(db.postings);
          transactionAmount = firstPosting.amount.abs();
        }

        for (final rowData in postingsWithAccounts) {
          final posting = rowData.readTable(db.postings);
          final account = rowData.readTable(db.accounts);
          if (posting.amount < 0) {
            fromAccountObj = account;
          } else if (posting.amount > 0) {
            toAccountObj = account;
          }
        }

        // 确定交易性质
        final nature = getTransactionNature(
            fromAccountObj?.accountType, toAccountObj?.accountType);

        resultList.add(TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccountObj,
          toAccount: toAccountObj,
          nature: nature,
        ));
      }
      return resultList;
    });
  }

  // Insert transaction
  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  // Update transaction
  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  // Delete transaction
  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.transactionId.equals(id))).go();
}
