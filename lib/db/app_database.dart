import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Table imports
import 'tables/account_table.dart';
import 'tables/transaction_table.dart';
import 'tables/posting_table.dart';
import 'tables/tag_table.dart';
import 'tables/transaction_tag_table.dart';

// DAO imports
import 'dao/account_dao.dart';
import 'dao/transaction_dao.dart';
import 'dao/posting_dao.dart';
import 'dao/tag_dao.dart';
import 'dao/transaction_tag_dao.dart';

import 'seed_data.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    Postings,
    Tags,
    TransactionTags,
  ],
  daos: [
    AccountDao,
    TransactionDao,
    PostingDao,
    TagDao,
    TransactionTagDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // 创建所有表
          await m.createAll();

          // 首次创建数据库时填充种子数据
          final seedData = SeedData(this);
          await seedData.seedDatabase();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flowm_database.sqlite'));
    return NativeDatabase(file);
  });
}
