import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Table imports
import 'tables/account_table.dart';
import 'tables/account_config_table.dart';
import 'tables/transaction_table.dart';
import 'tables/posting_table.dart';
import 'tables/tag_table.dart';
import 'tables/transaction_tag_table.dart';
import 'tables/ledger_table.dart';

// DAO imports
import 'dao/account_dao.dart';
import 'dao/transaction_dao.dart';
import 'dao/posting_dao.dart';
import 'dao/tag_dao.dart';
import 'dao/transaction_tag_dao.dart';
import 'dao/account_config_dao.dart';
import 'dao/ledger_dao.dart';

import 'seed_data.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    AccountConfigs,
    Transactions,
    Postings,
    Tags,
    TransactionTags,
    Ledgers,
  ],
  daos: [
    AccountDao,
    TransactionDao,
    PostingDao,
    TagDao,
    TransactionTagDao,
    AccountConfigDao,
    LedgerDao,
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

          // 添加性能优化索引
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_postings_account_id ON postings(account_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_postings_transaction_id ON postings(transaction_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id ON accounts(ledger_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_accounts_parent_id ON accounts(parent_account_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_accounts_type_ledger ON accounts(account_type, ledger_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date)');

          // 新增：专门为资产账户查询优化的复合索引
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_accounts_asset_active_ledger ON accounts(account_type, is_active, ledger_id) WHERE account_type = "ASSET"');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_postings_account_amount ON postings(account_id, amount)');

          // 新增：为交易关联查询优化的索引
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_ledger_date ON transactions(transaction_date) WHERE EXISTS (SELECT 1 FROM postings p JOIN accounts a ON p.account_id = a.account_id WHERE p.transaction_id = transactions.transaction_id)');

          // 首次创建数据库时填充种子数据
          final seedData = SeedData(this);
          await seedData.seedDatabase();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations
          if (from == 1 && to == 2) {
            // 添加索引的迁移逻辑
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_postings_account_id ON postings(account_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_postings_transaction_id ON postings(transaction_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_accounts_ledger_id ON accounts(ledger_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_accounts_parent_id ON accounts(parent_account_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_accounts_type_ledger ON accounts(account_type, ledger_id)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date)');

            // 新增的优化索引
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_accounts_asset_active_ledger ON accounts(account_type, is_active, ledger_id) WHERE account_type = "ASSET"');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_postings_account_amount ON postings(account_id, amount)');
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    print('dbFolder: ${dbFolder.path}');
    final file = File(p.join(dbFolder.path, 'flowm_database.sqlite'));
    return NativeDatabase(file);
  });
}
