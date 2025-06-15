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

  // Get transaction with amount by ID
  Future<TransactionWithAmount?> getTransactionWithAmountById(
      int transactionId) async {
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) {
      return null;
    }

    final postingsQuery = select(db.postings).join([
      innerJoin(
          db.accounts, db.accounts.accountId.equalsExp(db.postings.accountId)),
    ])
      ..where(db.postings.transactionId.equals(transaction.transactionId));

    final postingsWithAccounts = await postingsQuery.get();

    Account? fromAccountObj;
    Account? toAccountObj;
    double transactionAmount = 0;

    if (postingsWithAccounts.isNotEmpty) {
      final firstPosting = postingsWithAccounts.first.readTable(db.postings);
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

    final nature = getTransactionNature(
        fromAccountObj?.accountType, toAccountObj?.accountType);

    return TransactionWithAmount(
      transaction: transaction,
      amount: transactionAmount,
      fromAccount: fromAccountObj,
      toAccount: toAccountObj,
      nature: nature,
    );
  }

  // Watch all transactions (reactive stream)
  Stream<List<Transaction>> watchAllTransactions({int? ledgerId, int? limit}) {
    print('watchAllTransactions: $ledgerId, $limit');
    if (ledgerId == null) {
      var query = select(transactions)
        ..orderBy([
          (t) => OrderingTerm(
              expression: t.transactionDate, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.transactionId, mode: OrderingMode.desc)
        ]);
      if (limit != null && limit > 0) {
        query = query..limit(limit);
      }
      return query.watch();
    } else {
      // If ledgerId is provided, we need to find transactions
      // associated with accounts under that ledger.
      var queryBuilder = select(transactions).join([
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
        ]) // Use groupBy to ensure distinct transactions
        ..orderBy([
          OrderingTerm(
              expression: transactions.transactionDate,
              mode: OrderingMode.desc),
          OrderingTerm(
              expression: transactions.transactionId, mode: OrderingMode.desc)
        ]);

      if (limit != null && limit > 0) {
        queryBuilder = queryBuilder..limit(limit);
      }

      return queryBuilder.watch().map((typedResults) {
        // The typedResults are already ordered, limited, and represent distinct transactions
        // due to groupBy and orderBy/limit on the query.
        return typedResults.map((row) => row.readTable(transactions)).toList();
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
      {required int limit, required int offset, int? ledgerId}) {
    //日志 ledgerId
    print(
        'watchTransactionsWithAmountPaginated: ledgerId: $ledgerId, limit: $limit, offset: $offset');

    if (ledgerId != null) {
      // If ledgerId is provided, filter transactions by accounts under that ledger.
      final queryBuilder = select(transactions).join([
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
        ..groupBy([transactions.transactionId]) // Ensure distinct transactions
        ..orderBy([
          OrderingTerm(
              expression: transactions.transactionDate,
              mode: OrderingMode.desc),
          OrderingTerm(
              expression: transactions.transactionId, mode: OrderingMode.desc)
        ])
        ..limit(limit, offset: offset);

      return queryBuilder.watch().asyncMap((typedResults) async {
        final paginatedTransactionsList =
            typedResults.map((row) => row.readTable(transactions)).toList();

        if (paginatedTransactionsList.isEmpty) {
          return <TransactionWithAmount>[];
        }
        final resultList = <TransactionWithAmount>[];
        for (final transaction in paginatedTransactionsList) {
          final postingsQuery = select(db.postings).join([
            innerJoin(db.accounts,
                db.accounts.accountId.equalsExp(db.postings.accountId)),
          ])
            ..where(
                db.postings.transactionId.equals(transaction.transactionId));

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
    } else {
      // This part is executed only if ledgerId is null
      final paginatedTransactionsQuery = select(transactions)
        ..orderBy([
          (t) => OrderingTerm(
              expression: t.transactionDate, mode: OrderingMode.desc),
          (t) => OrderingTerm(
              expression: t.transactionId, mode: OrderingMode.desc),
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
            ..where(
                db.postings.transactionId.equals(transaction.transactionId));

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
        TransactionNature nature = TransactionNature.OTHER; // Default nature

        if (postingsWithAccounts.isNotEmpty) {
          // Attempt to determine amount more robustly if multiple postings exist
          // For simple two-posting transactions, one is positive, one is negative.
          // The absolute value of either could be the "amount" of the transaction.
          // We'll take the absolute amount of the first posting for simplicity,
          // assuming it represents the transaction's magnitude.
          // More complex transactions (e.g. splits) might need different logic.
          final firstPostingAmount =
              postingsWithAccounts.first.readTable(db.postings).amount;
          transactionAmount = firstPostingAmount.abs();

          // Determine from/to accounts and overall nature
          double totalPositive = 0;
          double totalNegative = 0;
          List<Account> positiveAccounts = [];
          List<Account> negativeAccounts = [];

          for (final rowData in postingsWithAccounts) {
            final posting = rowData.readTable(db.postings);
            final account = rowData.readTable(db.accounts);
            if (posting.amount > 0) {
              totalPositive += posting.amount;
              positiveAccounts.add(account);
            } else if (posting.amount < 0) {
              totalNegative += posting.amount; // amount is negative
              negativeAccounts.add(account);
            }
          }

          // Simplified from/to logic: first negative as from, first positive as to
          // This might need refinement for complex transactions (e.g., multiple from/to)
          fromAccountObj =
              negativeAccounts.isNotEmpty ? negativeAccounts.first : null;
          toAccountObj =
              positiveAccounts.isNotEmpty ? positiveAccounts.first : null;

          nature = getTransactionNature(
              fromAccountObj?.accountType, toAccountObj?.accountType);

          // If it's a simple transfer or expense/income, amount might be more clearly defined
          // For example, if one posting is ASSET and negative, and other is EXPENSE and positive
          // the amount is the value of that movement.
          // The current transactionAmount from firstPosting.amount.abs() is a common case.
        }

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

  // Watch transactions with amount by date range
  Stream<List<TransactionWithAmount>> watchTransactionsWithAmountByDateRange(
      DateTime startDate, DateTime endDate, int? ledgerId) {
    if (ledgerId == null) {
      return Stream.value([]);
    }

    // Subquery to get transaction_ids that are associated with the given ledgerId
    final transactionIdsInLedgerSubquery = selectOnly(db.postings,
        distinct: true)
      ..addColumns([db.postings.transactionId])
      ..join([
        innerJoin(
            db.accounts, db.accounts.accountId.equalsExp(db.postings.accountId))
      ])
      ..where(db.accounts.ledgerId.equals(ledgerId));

    final query = select(transactions).join([
      // Left join postings, as a transaction might not have postings (though unlikely in a valid system)
      leftOuterJoin(db.postings,
          db.postings.transactionId.equalsExp(transactions.transactionId)),
      // Left join accounts from postings, as a posting must have an account
      leftOuterJoin(
          db.accounts, db.accounts.accountId.equalsExp(db.postings.accountId)),
    ])
      ..where(transactions.transactionDate.isBetweenValues(startDate, endDate) &
          transactions.transactionId.isInQuery(transactionIdsInLedgerSubquery))
      ..orderBy([
        OrderingTerm(
            expression: transactions.transactionDate, mode: OrderingMode.desc),
        OrderingTerm(
            expression: transactions.transactionId, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) {
      final Map<int, TransactionWithAmount> tempResults = {};
      final Map<int, List<TypedResult>> transactionRows = {};

      // Group rows by transactionId first
      for (final row in rows) {
        final transaction = row.readTable(transactions);
        transactionRows
            .putIfAbsent(transaction.transactionId, () => [])
            .add(row);
      }

      transactionRows.forEach((transactionId, rowsOfTransaction) {
        if (rowsOfTransaction.isEmpty) return;

        final transaction = rowsOfTransaction.first.readTable(transactions);
        Account? fromAccountObj;
        Account? toAccountObj;
        double transactionAmount = 0;
        TransactionNature nature = TransactionNature.OTHER;

        // Consolidate postings for the current transaction
        List<Account> positiveAccounts = [];
        List<Account> negativeAccounts = [];
        bool amountSet = false;

        for (final rowData in rowsOfTransaction) {
          final posting = rowData.readTableOrNull(db.postings);
          final account = rowData.readTableOrNull(db.accounts);

          if (posting != null && account != null) {
            if (!amountSet) {
              // Heuristic: take the first posting's amount as the transaction's face value
              transactionAmount = posting.amount.abs();
              amountSet = true;
            }
            if (posting.amount > 0) {
              positiveAccounts.add(account);
            } else if (posting.amount < 0) {
              negativeAccounts.add(account);
            }
          }
        }

        fromAccountObj =
            negativeAccounts.isNotEmpty ? negativeAccounts.first : null;
        toAccountObj =
            positiveAccounts.isNotEmpty ? positiveAccounts.first : null;

        nature = getTransactionNature(
            fromAccountObj?.accountType, toAccountObj?.accountType);

        tempResults[transactionId] = TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccountObj,
          toAccount: toAccountObj,
          nature: nature,
        );
      });

      // Preserve original order based on transaction date and ID (descending)
      final resultList = tempResults.values.toList();
      resultList.sort((a, b) {
        int dateComp = b.transaction.transactionDate
            .compareTo(a.transaction.transactionDate);
        if (dateComp != 0) return dateComp;
        return b.transaction.transactionId
            .compareTo(a.transaction.transactionId);
      });

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
    print('watchLatestTransactionsByLedgerId: $ledgerId, $limit');
    // Call watchAllTransactions, which now handles ordering and limiting at the DB level
    return watchAllTransactions(ledgerId: ledgerId, limit: limit)
        // The .map((transactionsList) => transactionsList.take(limit).toList()) is now removed
        .asyncMap((latestTransactionsList) async {
      // latestTransactionsList is already correctly ordered and limited
      if (latestTransactionsList.isEmpty) {
        return <TransactionWithAmount>[];
      }
      for (final transaction in latestTransactionsList) {
        print('Transaction ID: ${transaction.transactionId}');
        print('Transaction Date: ${transaction.transactionDate}');
        print('Transaction Description: ${transaction.description}');
        print('Is Recurring: ${transaction.isRecurring}');
        print('---');
      }

      final resultList = <TransactionWithAmount>[];

      for (final transaction in latestTransactionsList) {
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

          for (final rowData in postingsWithAccounts) {
            final posting = rowData.readTable(db.postings);
            final account = rowData.readTable(db.accounts);
            if (posting.amount < 0) {
              fromAccountObj = account;
            } else if (posting.amount > 0) {
              toAccountObj = account;
            }
          }
        }

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

  // 根据账户ID和日期范围查询相关的所有交易记录
  Stream<List<TransactionWithAmount>> watchTransactionsByAccountAndDateRange({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return customSelect(
      '''
      SELECT DISTINCT 
        t.transaction_id,
        t.transaction_date,
        t.description,
        t.is_recurring,
        t.created_at,
        p1.amount as target_account_amount,
        a1.account_id as target_account_id,
        a1.account_name as target_account_name,
        a1.account_type as target_account_type,
        a1.ledger_id as target_ledger_id,
        a1.full_path as target_full_path,
        a1.is_active as target_is_active,
        a1.parent_account_id as target_parent_account_id,
        a1.created_at as target_account_created_at,
        p2.amount as other_account_amount,
        a2.account_id as other_account_id,
        a2.account_name as other_account_name,
        a2.account_type as other_account_type,
        a2.ledger_id as other_ledger_id,
        a2.full_path as other_full_path,
        a2.is_active as other_is_active,
        a2.parent_account_id as other_parent_account_id,
        a2.created_at as other_account_created_at
      FROM transactions t
      INNER JOIN postings p1 ON t.transaction_id = p1.transaction_id
      INNER JOIN accounts a1 ON p1.account_id = a1.account_id
      LEFT JOIN postings p2 ON t.transaction_id = p2.transaction_id AND p2.account_id != ?
      LEFT JOIN accounts a2 ON p2.account_id = a2.account_id
      WHERE p1.account_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
      ORDER BY t.transaction_date DESC, t.transaction_id DESC
      ''',
      variables: [
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
      readsFrom: {transactions, postings, accounts},
    ).watch().map((rows) {
      return rows.map((row) {
        // 构建目标账户（就是我们查询的账户）
        final targetAccount = Account(
          accountId: row.read<int>('target_account_id'),
          accountName: row.read<String>('target_account_name'),
          accountType: AccountType.values.firstWhere(
            (type) =>
                type.toString().split('.').last ==
                row.read<String>('target_account_type'),
            orElse: () => AccountType.ASSET,
          ),
          ledgerId: row.read<int>('target_ledger_id'),
          fullPath: row.read<String>('target_full_path'),
          isActive: row.read<bool>('target_is_active'),
          createdAt: row.read<DateTime>('target_account_created_at'),
          parentAccountId: row.readNullable<int>('target_parent_account_id'),
        );

        // 构建对方账户（如果存在）
        Account? otherAccount;
        if (row.readNullable<int>('other_account_id') != null) {
          otherAccount = Account(
            accountId: row.read<int>('other_account_id'),
            accountName: row.read<String>('other_account_name'),
            accountType: AccountType.values.firstWhere(
              (type) =>
                  type.toString().split('.').last ==
                  row.read<String>('other_account_type'),
              orElse: () => AccountType.ASSET,
            ),
            ledgerId: row.read<int>('other_ledger_id'),
            fullPath: row.read<String>('other_full_path'),
            isActive: row.read<bool>('other_is_active'),
            createdAt: row.read<DateTime>('other_account_created_at'),
            parentAccountId: row.readNullable<int>('other_parent_account_id'),
          );
        }

        // 构建交易记录
        final transaction = Transaction(
          transactionId: row.read<int>('transaction_id'),
          transactionDate: row.read<DateTime>('transaction_date'),
          description: row.readNullable<String>('description'),
          isRecurring: row.read<bool>('is_recurring'),
          createdAt: row.read<DateTime>('created_at'),
        );

        // 获取目标账户的金额（绝对值）
        final targetAmount = row.read<double>('target_account_amount');
        final transactionAmount = targetAmount.abs();

        // 确定 fromAccount 和 toAccount
        Account? fromAccount;
        Account? toAccount;

        if (targetAmount < 0) {
          // 目标账户金额为负，说明是借方，资金从目标账户流出
          fromAccount = targetAccount;
          toAccount = otherAccount;
        } else {
          // 目标账户金额为正，说明是贷方，资金流入目标账户
          fromAccount = otherAccount;
          toAccount = targetAccount;
        }

        // 确定交易性质
        final nature = getTransactionNature(
          fromAccount?.accountType,
          toAccount?.accountType,
        );

        return TransactionWithAmount(
          transaction: transaction,
          amount: transactionAmount,
          fromAccount: fromAccount,
          toAccount: toAccount,
          nature: nature,
        );
      }).toList();
    });
  }

  // 根据账户ID和日期范围查询相关的所有交易记录（Future版本，一次性加载）
  Future<List<TransactionWithAmount>> getTransactionsByAccountAndDateRange({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';

    final results = await customSelect(
      '''
      SELECT DISTINCT 
        t.transaction_id,
        t.transaction_date,
        t.description,
        t.is_recurring,
        t.created_at,
        p1.amount as target_account_amount,
        a1.account_id as target_account_id,
        a1.account_name as target_account_name,
        a1.account_type as target_account_type,
        a1.ledger_id as target_ledger_id,
        a1.full_path as target_full_path,
        a1.is_active as target_is_active,
        a1.parent_account_id as target_parent_account_id,
        a1.created_at as target_account_created_at,
        p2.amount as other_account_amount,
        a2.account_id as other_account_id,
        a2.account_name as other_account_name,
        a2.account_type as other_account_type,
        a2.ledger_id as other_ledger_id,
        a2.full_path as other_full_path,
        a2.is_active as other_is_active,
        a2.parent_account_id as other_parent_account_id,
        a2.created_at as other_account_created_at
      FROM transactions t
      INNER JOIN postings p1 ON t.transaction_id = p1.transaction_id
      INNER JOIN accounts a1 ON p1.account_id = a1.account_id
      LEFT JOIN postings p2 ON t.transaction_id = p2.transaction_id AND p2.account_id != ?
      LEFT JOIN accounts a2 ON p2.account_id = a2.account_id
      WHERE p1.account_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
      ORDER BY t.transaction_date DESC, t.transaction_id DESC
      $limitClause
      ''',
      variables: [
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
      readsFrom: {transactions, postings, accounts},
    ).get();

    return results.map((row) {
      // 构建目标账户（就是我们查询的账户）
      final targetAccount = Account(
        accountId: row.read<int>('target_account_id'),
        accountName: row.read<String>('target_account_name'),
        accountType: AccountType.values.firstWhere(
          (type) =>
              type.toString().split('.').last ==
              row.read<String>('target_account_type'),
          orElse: () => AccountType.ASSET,
        ),
        ledgerId: row.read<int>('target_ledger_id'),
        fullPath: row.read<String>('target_full_path'),
        isActive: row.read<bool>('target_is_active'),
        createdAt: row.read<DateTime>('target_account_created_at'),
        parentAccountId: row.readNullable<int>('target_parent_account_id'),
      );

      // 构建对方账户（如果存在）
      Account? otherAccount;
      if (row.readNullable<int>('other_account_id') != null) {
        otherAccount = Account(
          accountId: row.read<int>('other_account_id'),
          accountName: row.read<String>('other_account_name'),
          accountType: AccountType.values.firstWhere(
            (type) =>
                type.toString().split('.').last ==
                row.read<String>('other_account_type'),
            orElse: () => AccountType.ASSET,
          ),
          ledgerId: row.read<int>('other_ledger_id'),
          fullPath: row.read<String>('other_full_path'),
          isActive: row.read<bool>('other_is_active'),
          createdAt: row.read<DateTime>('other_account_created_at'),
          parentAccountId: row.readNullable<int>('other_parent_account_id'),
        );
      }

      // 构建交易记录
      final transaction = Transaction(
        transactionId: row.read<int>('transaction_id'),
        transactionDate: row.read<DateTime>('transaction_date'),
        description: row.readNullable<String>('description'),
        isRecurring: row.read<bool>('is_recurring'),
        createdAt: row.read<DateTime>('created_at'),
      );

      // 获取目标账户的金额（绝对值）
      final targetAmount = row.read<double>('target_account_amount');
      final transactionAmount = targetAmount.abs();

      // 确定 fromAccount 和 toAccount
      Account? fromAccount;
      Account? toAccount;

      if (targetAmount < 0) {
        // 目标账户金额为负，说明是借方，资金从目标账户流出
        fromAccount = targetAccount;
        toAccount = otherAccount;
      } else {
        // 目标账户金额为正，说明是贷方，资金流入目标账户
        fromAccount = otherAccount;
        toAccount = targetAccount;
      }

      // 确定交易性质
      final nature = getTransactionNature(
        fromAccount?.accountType,
        toAccount?.accountType,
      );

      return TransactionWithAmount(
        transaction: transaction,
        amount: transactionAmount,
        fromAccount: fromAccount,
        toAccount: toAccount,
        nature: nature,
      );
    }).toList();
  }
}
