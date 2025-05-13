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
  Stream<List<Transaction>> watchAllTransactions() =>
      _transactionDao.watchAllTransactions();

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
}
