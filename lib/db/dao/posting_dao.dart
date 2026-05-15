import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/posting_table.dart';

part 'posting_dao.g.dart';

@DriftAccessor(tables: [Postings])
class PostingDao extends DatabaseAccessor<AppDatabase> with _$PostingDaoMixin {
  PostingDao(super.db);

  // Get postings by transaction ID
  Future<List<Posting>> getPostingsByTransactionId(int transactionId) =>
      (select(postings)..where((p) => p.transactionId.equals(transactionId)))
          .get();

  // Get postings by account ID
  Future<List<Posting>> getPostingsByAccountId(int accountId) =>
      (select(postings)..where((p) => p.accountId.equals(accountId))).get();

  // Watch postings by transaction ID (reactive stream)
  Stream<List<Posting>> watchPostingsByTransactionId(int transactionId) =>
      (select(postings)..where((p) => p.transactionId.equals(transactionId)))
          .watch();

  // Insert posting
  Future<int> insertPosting(PostingsCompanion posting) =>
      into(postings).insert(posting);

  // Insert multiple postings
  Future<void> insertPostings(List<PostingsCompanion> postingsList) async {
    await batch((batch) {
      batch.insertAll(postings, postingsList);
    });
  }

  // Update posting
  Future<bool> updatePosting(PostingsCompanion posting) =>
      update(postings).replace(posting);

  // Delete posting
  Future<int> deletePosting(int id) =>
      (delete(postings)..where((p) => p.postingId.equals(id))).go();

  // Delete postings by transaction ID
  Future<int> deletePostingsByTransactionId(int transactionId) =>
      (delete(postings)..where((p) => p.transactionId.equals(transactionId)))
          .go();
}
