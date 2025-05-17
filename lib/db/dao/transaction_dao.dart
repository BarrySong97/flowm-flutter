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
  Stream<List<Transaction>> watchAllTransactions({int? ledgerId}) {
    if (ledgerId == null) {
      return select(transactions).watch();
    } else {
      // If ledgerId is provided, we need to find transactions
      // associated with accounts under that ledger.
      final query = select(transactions).join([
        innerJoin(
          db.postings,
          db.postings.transactionId.equalsExp(transactions.transactionId),
        ),
        innerJoin(
          db.accounts,
          db.accounts.accountId.equalsExp(db.postings.accountId),
        ),
      ])
        ..where(db.accounts.ledgerId.equals(ledgerId))
        ..groupBy([
          transactions.transactionId
        ]); // Use groupBy to ensure distinct transactions

      return query.watch().map((rows) {
        // Map rows to distinct transactions
        final transactionSet = <Transaction>{};
        for (final row in rows) {
          transactionSet.add(row.readTable(transactions));
        }
        return transactionSet.toList()
          ..sort((a, b) => b.transactionDate
              .compareTo(a.transactionDate)); // Optional: maintain order
      });
    }
  }

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
      ORDER BY t.transaction_date ASC
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

  // 新的优化版本
  Stream<List<TransactionWithAmount>> watchLatestTransactionsByLedgerId(
      int ledgerId, int limit) {
    return customSelect(
      '''
      WITH RankedTransactions AS (
        SELECT DISTINCT 
          t.*,
          p.amount,
          a.account_id,
          a.account_name,
          a.account_type,
          ROW_NUMBER() OVER (PARTITION BY t.transaction_id ORDER BY 
            CASE WHEN p.amount < 0 THEN 1 ELSE 2 END) as row_num
        FROM transactions t
        INNER JOIN postings p ON t.transaction_id = p.transaction_id
        INNER JOIN accounts a ON p.account_id = a.account_id
        WHERE a.ledger_id = ?
      )
      SELECT 
        t1.transaction_id,
        t1.transaction_date,
        t1.description,
        t1.is_recurring,
        ABS(t1.amount) as transaction_amount,
        t1.account_id as from_account_id,
        t1.account_name as from_account_name,
        t1.account_type as from_account_type,
        t2.account_id as to_account_id,
        t2.account_name as to_account_name,
        t2.account_type as to_account_type
      FROM RankedTransactions t1
      LEFT JOIN RankedTransactions t2 ON 
        t1.transaction_id = t2.transaction_id AND t2.row_num = 2
      WHERE t1.row_num = 1
      ORDER BY t1.transaction_date DESC, t1.transaction_id DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(ledgerId),
        Variable.withInt(limit),
      ],
      readsFrom: {transactions, postings, accounts},
    ).watch().map((rows) {
      return rows.map((row) {
        final fromAccount = Account(
          accountId: row.read<int>('from_account_id'),
          accountName: row.read<String>('from_account_name'),
          accountType: AccountType.values.firstWhere(
            (type) =>
                type.toString().split('.').last ==
                row.read<String>('from_account_type'),
            orElse: () => AccountType.ASSET,
          ),
          ledgerId: ledgerId,
          fullPath:
              row.read<String>('from_account_name'), // 使用账户名作为临时的 fullPath
          isActive: true,
          createdAt: DateTime.now(),
          parentAccountId: null,
        );

        final toAccount = Account(
          accountId: row.read<int>('to_account_id'),
          accountName: row.read<String>('to_account_name'),
          accountType: AccountType.values.firstWhere(
            (type) =>
                type.toString().split('.').last ==
                row.read<String>('to_account_type'),
            orElse: () => AccountType.ASSET,
          ),
          ledgerId: ledgerId,
          fullPath: row.read<String>('to_account_name'), // 使用账户名作为临时的 fullPath
          isActive: true,
          createdAt: DateTime.now(),
          parentAccountId: null,
        );

        final transaction = Transaction(
          transactionId: row.read<int>('transaction_id'),
          transactionDate: row.read<DateTime>('transaction_date'),
          description: row.readNullable<String>('description'),
          isRecurring: row.read<bool>('is_recurring'),
          createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        );

        final nature = getTransactionNature(
          fromAccount.accountType,
          toAccount.accountType,
        );

        return TransactionWithAmount(
          transaction: transaction,
          amount: row.read<double>('transaction_amount'),
          fromAccount: fromAccount,
          toAccount: toAccount,
          nature: nature,
        );
      }).toList();
    });
  }
}
