import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
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
