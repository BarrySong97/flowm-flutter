import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/dao/transaction_dao.dart';
import '../../db/dao/posting_dao.dart';
import '../../db/dao/tag_dao.dart';
import '../../db/dao/transaction_tag_dao.dart';

/// 全局数据库实例提供者
///
/// 通过Riverpod管理AppDatabase的单例实例，确保整个应用程序
/// 只有一个数据库连接实例被创建和使用。
final databaseProvider = Provider<AppDatabase>((ref) {
  // 创建数据库实例
  final database = AppDatabase();

  // 确保当Provider被销毁时关闭数据库连接
  ref.onDispose(() {
    database.close();
  });

  return database;
});

/// 账户DAO提供者
final accountDaoProvider = Provider<AccountDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.accountDao;
});

/// 交易DAO提供者
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.transactionDao;
});

/// 分录DAO提供者
final postingDaoProvider = Provider<PostingDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.postingDao;
});

/// 标签DAO提供者
final tagDaoProvider = Provider<TagDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.tagDao;
});

/// 交易标签关联DAO提供者
final transactionTagDaoProvider = Provider<TransactionTagDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.transactionTagDao;
});
