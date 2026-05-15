import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/dao/transaction_dao.dart';
import '../../db/dao/posting_dao.dart';
import '../../db/dao/tag_dao.dart';
import '../../db/dao/transaction_tag_dao.dart';
import '../../db/dao/ledger_dao.dart';

/// 数据库刷新触发器
///
/// 用于触发数据库连接的重新建立，当该provider被invalidate时，
/// 所有依赖它的provider都会重新创建
final databaseRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 全局数据库实例提供者
///
/// 通过Riverpod管理AppDatabase的单例实例，确保整个应用程序
/// 只有一个数据库连接实例被创建和使用。
/// 当databaseRefreshTriggerProvider发生变化时，会重新创建数据库连接。
final databaseProvider = Provider<AppDatabase>((ref) {
  // 监听刷新触发器，确保在触发器变化时重新创建数据库
  ref.watch(databaseRefreshTriggerProvider);

  AppLogger.debug('[DatabaseProvider] 创建新的数据库连接实例');

  // 创建数据库实例
  final database = AppDatabase();

  // 确保当Provider被销毁时关闭数据库连接
  ref.onDispose(() {
    AppLogger.debug('[DatabaseProvider] 关闭数据库连接');
    database.close();
  });

  return database;
});

/// 数据库初始化状态提供者
///
/// 检查数据库是否已经初始化完成（即是否有数据）
final databaseInitializationProvider = FutureProvider<bool>((ref) async {
  final database = ref.watch(databaseProvider);

  try {
    // 检查是否有账本数据，如果有则认为数据库已初始化
    final ledgers = await database.ledgerDao.getAllLedgers();
    return ledgers.isNotEmpty;
  } catch (e) {
    // 如果查询失败，认为数据库尚未初始化
    return false;
  }
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

/// 账本DAO提供者
final ledgerDaoProvider = Provider<LedgerDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.ledgerDao;
});
