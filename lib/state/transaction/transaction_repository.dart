import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/transaction_dao.dart';
import '../database/database_provider.dart';

/// 交易仓库提供者，用于封装交易相关的数据库操作
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final transactionDao = ref.watch(transactionDaoProvider);
  return TransactionRepository(transactionDao);
});

/// 交易仓库类
///
/// 封装与交易相关的所有数据库操作，提供更高级别的业务逻辑方法
class TransactionRepository {
  final TransactionDao _transactionDao;

  TransactionRepository(this._transactionDao);

  /// 获取所有交易
  Future<List<Transaction>> getAllTransactions() =>
      _transactionDao.getAllTransactions();

  /// 监听所有交易（响应式流）
  Stream<List<Transaction>> watchAllTransactions({int? ledgerId}) =>
      _transactionDao.watchAllTransactions(ledgerId: ledgerId);

  /// 根据时间范围监听交易
  Stream<List<Transaction>> watchTransactionsByDateRange(
          DateTime startDate, DateTime endDate) =>
      _transactionDao.watchTransactionsByDateRange(startDate, endDate);

  /// 获取交易详情
  Future<Transaction?> getTransactionById(int id) =>
      _transactionDao.getTransactionById(id);

  /// 创建新交易
  Future<int> createTransaction({
    required DateTime date,
    String? description,
    bool isRecurring = false,
  }) {
    return _transactionDao.insertTransaction(TransactionsCompanion.insert(
      transactionDate: date,
      description: Value(description),
      isRecurring: Value(isRecurring),
    ));
  }

  /// 更新交易
  Future<bool> updateTransaction({
    required int id,
    DateTime? date,
    String? description,
    bool? isRecurring,
  }) {
    return _transactionDao.updateTransaction(TransactionsCompanion(
      transactionId: Value(id),
      transactionDate: date != null ? Value(date) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      isRecurring:
          isRecurring != null ? Value(isRecurring) : const Value.absent(),
    ));
  }

  /// 删除交易
  Future<int> deleteTransaction(int id) =>
      _transactionDao.deleteTransaction(id);

  /// 复制交易
  Future<int> duplicateTransaction(Transaction transaction) {
    return _transactionDao.insertTransaction(TransactionsCompanion.insert(
      transactionDate: DateTime.now(),
      description: Value(transaction.description),
      isRecurring: Value(transaction.isRecurring),
    ));
  }

  /// 获取今日交易
  Stream<List<Transaction>> watchTodayTransactions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return watchTransactionsByDateRange(startOfDay, endOfDay);
  }

  /// 获取本周交易
  Stream<List<Transaction>> watchThisWeekTransactions() {
    final now = DateTime.now();
    // 找出本周的第一天（星期一）
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
    // 找出本周的最后一天（星期日）
    final lastDayOfWeek = now.add(Duration(days: 7 - now.weekday));
    final endOfWeek = DateTime(
        lastDayOfWeek.year, lastDayOfWeek.month, lastDayOfWeek.day, 23, 59, 59);
    return watchTransactionsByDateRange(startOfWeek, endOfWeek);
  }

  /// 获取本月交易
  Stream<List<Transaction>> watchThisMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 0, 23, 59, 59)
        : DateTime(now.year + 1, 1, 0, 23, 59, 59);
    return watchTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  /// 获取最新的交易
  Stream<List<TransactionWithAmount>> watchLatestTransactions(
      {int? ledgerId, int limit = 10}) {
    return _transactionDao.watchLatestTransactionsByLedgerId(ledgerId!, limit);
  }

  /// 获取指定账本的最新交易
  Stream<List<TransactionWithAmount>> _getLatestTransactionsByLedger(
      int ledgerId, int limit) {
    // 首先获取与该账本相关的账户ID
    return _transactionDao.db.accountDao
        .watchAccountsByLedgerId(ledgerId)
        .asyncMap((accounts) async {
      if (accounts.isEmpty) {
        return <TransactionWithAmount>[];
      }

      // 获取这些账户相关的accountIds
      final accountIds = accounts.map((account) => account.accountId).toSet();

      // 通过accountIds查找相关的交易
      return await _transactionDao
          .watchLatestTransactionsByAccountIds(
              accountIds: accountIds, limit: limit)
          .first;
    });
  }

  /// 获取分页的交易记录 (TransactionWithAmount)
  Stream<List<TransactionWithAmount>> watchTransactionsWithAmountPaginated(
          {required int limit, required int offset, int? ledgerId}) =>
      _transactionDao.watchTransactionsWithAmountPaginated(
          limit: limit, offset: offset, ledgerId: ledgerId);

  /// 获取某一天交易
  Stream<List<TransactionWithAmount>> watchTransactionsByDay(DateTime day) =>
      _transactionDao.watchTransactionsWithAmountByDay(day);

  /// 根据时间范围监听交易 (TransactionWithAmount)
  Stream<List<TransactionWithAmount>> watchTransactionsWithAmountByDateRange(
          DateTime startDate, DateTime endDate, int? ledgerId) =>
      _transactionDao.watchTransactionsWithAmountByDateRange(
          startDate, endDate, ledgerId);

  /// 根据ID获取单个交易及其详情
  Future<TransactionWithAmount?> getTransactionWithAmountById(
          int transactionId) =>
      _transactionDao.getTransactionWithAmountById(transactionId);

  /// 更新包含记账分录的完整交易
  Future<void> updateTransactionWithPostings({
    required int transactionId,
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime transactionDate,
    String? description,
  }) async {
    return _transactionDao.db.transaction(() async {
      // 1. 更新 Transaction 记录
      await _transactionDao.updateTransaction(TransactionsCompanion(
        transactionId: Value(transactionId),
        transactionDate: Value(transactionDate),
        description: Value(description),
      ));

      // 2. 找到并更新 Postings
      // 假设每个交易总有两条posting，一出一入
      final postings =
          await (_transactionDao.db.select(_transactionDao.db.postings)
                ..where((p) => p.transactionId.equals(transactionId)))
              .get();

      final fromPosting = postings.firstWhere((p) => p.amount < 0);
      final toPosting = postings.firstWhere((p) => p.amount > 0);

      // 更新 fromAccount 的 Posting
      await (_transactionDao.db.update(_transactionDao.db.postings)
            ..where((p) => p.postingId.equals(fromPosting.postingId)))
          .write(PostingsCompanion(
        accountId: Value(fromAccountId),
        amount: Value(-amount),
      ));

      // 更新 toAccount 的 Posting
      await (_transactionDao.db.update(_transactionDao.db.postings)
            ..where((p) => p.postingId.equals(toPosting.postingId)))
          .write(PostingsCompanion(
        accountId: Value(toAccountId),
        amount: Value(amount),
      ));
    });
  }

  /// 创建一笔包含记账分录的完整交易
  ///
  /// [fromAccountId] - 资金来源账户ID
  /// [toAccountId] - 资金去向账户ID
  /// [amount] - 交易金额 (正数)
  /// [transactionDate] - 交易日期
  /// [description] - 交易描述
  Future<void> createTransactionWithPostings({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime transactionDate,
    String? description,
  }) async {
    return _transactionDao.db.transaction(() async {
      // 1. 创建 Transaction 记录
      final transactionId = await _transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          transactionDate: transactionDate,
          description: Value(description),
        ),
      );

      // 2. 创建两条 Posting 记录
      // fromAccount 的 Posting (资金减少)
      await _transactionDao.db.postings.insertOne(
        PostingsCompanion.insert(
          transactionId: transactionId,
          accountId: fromAccountId,
          amount: -amount, // 金额为负
        ),
      );

      // toAccount 的 Posting (资金增加)
      await _transactionDao.db.postings.insertOne(
        PostingsCompanion.insert(
          transactionId: transactionId,
          accountId: toAccountId,
          amount: amount, // 金额为正
        ),
      );
    });
  }
}
