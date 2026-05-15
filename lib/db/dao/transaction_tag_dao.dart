import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_tag_table.dart';

part 'transaction_tag_dao.g.dart';

@DriftAccessor(tables: [TransactionTags])
class TransactionTagDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionTagDaoMixin {
  TransactionTagDao(super.db);

  // Get all tags for a transaction
  Future<List<TransactionTag>> getTagsByTransactionId(int transactionId) =>
      (select(transactionTags)
            ..where((tt) => tt.transactionId.equals(transactionId)))
          .get();

  // Get all transactions for a tag
  Future<List<TransactionTag>> getTransactionsByTagId(int tagId) =>
      (select(transactionTags)..where((tt) => tt.tagId.equals(tagId))).get();

  // Watch tags for a transaction (reactive stream)
  Stream<List<TransactionTag>> watchTagsByTransactionId(int transactionId) =>
      (select(transactionTags)
            ..where((tt) => tt.transactionId.equals(transactionId)))
          .watch();

  // Insert transaction tag link
  Future<void> insertTransactionTag(TransactionTagsCompanion transactionTag) =>
      into(transactionTags).insert(transactionTag);

  // Delete transaction tag link
  Future<int> deleteTransactionTag(int transactionId, int tagId) =>
      (delete(transactionTags)
            ..where((tt) =>
                tt.transactionId.equals(transactionId) &
                tt.tagId.equals(tagId)))
          .go();

  // Delete all tags for a transaction
  Future<int> deleteAllTagsForTransaction(int transactionId) =>
      (delete(transactionTags)
            ..where((tt) => tt.transactionId.equals(transactionId)))
          .go();
}
