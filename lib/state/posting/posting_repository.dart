import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/posting_dao.dart';
import '../database/database_provider.dart';

/// 分录仓库提供者，用于封装分录相关的数据库操作
final postingRepositoryProvider = Provider<PostingRepository>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return PostingRepository(postingDao);
});

/// 分录仓库类
///
/// 封装与分录相关的所有数据库操作，提供更高级别的业务逻辑方法
class PostingRepository {
  final PostingDao _postingDao;

  PostingRepository(this._postingDao);

  /// 获取交易的所有分录
  Future<List<Posting>> getPostingsByTransactionId(int transactionId) =>
      _postingDao.getPostingsByTransactionId(transactionId);

  /// 获取账户的所有分录
  Future<List<Posting>> getPostingsByAccountId(int accountId) =>
      _postingDao.getPostingsByAccountId(accountId);

  /// 监听交易的所有分录（响应式流）
  Stream<List<Posting>> watchPostingsByTransactionId(int transactionId) =>
      _postingDao.watchPostingsByTransactionId(transactionId);

  /// 创建新分录
  Future<int> createPosting({
    required int transactionId,
    required int accountId,
    required double amount,
    String? postingTag,
  }) {
    return _postingDao.insertPosting(PostingsCompanion.insert(
      transactionId: transactionId,
      accountId: accountId,
      amount: amount,
      postingTag: Value(postingTag),
    ));
  }

  /// 批量创建分录
  Future<void> createPostings(List<PostingInput> postings) async {
    final companions = postings
        .map((input) => PostingsCompanion.insert(
              transactionId: input.transactionId,
              accountId: input.accountId,
              amount: input.amount,
              postingTag: Value(input.postingTag),
            ))
        .toList();

    await _postingDao.insertPostings(companions);
  }

  /// 更新分录
  Future<bool> updatePosting({
    required int id,
    int? transactionId,
    int? accountId,
    double? amount,
    String? postingTag,
  }) {
    return _postingDao.updatePosting(PostingsCompanion(
      postingId: Value(id),
      transactionId:
          transactionId != null ? Value(transactionId) : const Value.absent(),
      accountId: accountId != null ? Value(accountId) : const Value.absent(),
      amount: amount != null ? Value(amount) : const Value.absent(),
      postingTag: postingTag != null ? Value(postingTag) : const Value.absent(),
    ));
  }

  /// 删除分录
  Future<int> deletePosting(int id) => _postingDao.deletePosting(id);

  /// 删除交易的所有分录
  Future<int> deletePostingsByTransactionId(int transactionId) =>
      _postingDao.deletePostingsByTransactionId(transactionId);

  /// 获取交易的借方总额
  Future<double> getDebitTotalForTransaction(int transactionId) async {
    final postings = await getPostingsByTransactionId(transactionId);
    return postings
        .where((posting) => posting.amount > 0)
        .fold<double>(0.0, (sum, posting) => sum + posting.amount);
  }

  /// 获取交易的贷方总额
  Future<double> getCreditTotalForTransaction(int transactionId) async {
    final postings = await getPostingsByTransactionId(transactionId);
    return postings
        .where((posting) => posting.amount < 0)
        .fold<double>(0.0, (sum, posting) => sum + posting.amount.abs());
  }

  /// 检查交易是否平衡（借贷平衡）
  Future<bool> isTransactionBalanced(int transactionId) async {
    final debitTotal = await getDebitTotalForTransaction(transactionId);
    final creditTotal = await getCreditTotalForTransaction(transactionId);
    // 允许一定的舍入误差
    return (debitTotal - creditTotal).abs() < 0.001;
  }
}

/// 用于批量创建分录的输入模型
class PostingInput {
  final int transactionId;
  final int accountId;
  final double amount;
  final String? postingTag;

  PostingInput({
    required this.transactionId,
    required this.accountId,
    required this.amount,
    this.postingTag,
  });
}
