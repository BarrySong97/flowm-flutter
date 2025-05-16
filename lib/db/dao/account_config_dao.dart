import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/account_config_table.dart';

part 'account_config_dao.g.dart';

@DriftAccessor(tables: [AccountConfigs])
class AccountConfigDao extends DatabaseAccessor<AppDatabase>
    with _$AccountConfigDaoMixin {
  AccountConfigDao(AppDatabase db) : super(db);

  // Basic CRUD operations

  Future<List<AccountConfig>> getAllAccountConfigs() =>
      select(accountConfigs).get();

  Stream<List<AccountConfig>> watchAllAccountConfigs() =>
      select(accountConfigs).watch();

  Future<AccountConfig?> getAccountConfigById(int accountId) {
    return (select(accountConfigs)
          ..where((tbl) => tbl.accountId.equals(accountId)))
        .getSingleOrNull();
  }

  Stream<AccountConfig?> watchAccountConfigById(int accountId) {
    return (select(accountConfigs)
          ..where((tbl) => tbl.accountId.equals(accountId)))
        .watchSingleOrNull();
  }

  Future<int> insertAccountConfig(Insertable<AccountConfig> config) =>
      into(accountConfigs).insert(config);

  Future<bool> updateAccountConfig(Insertable<AccountConfig> config) =>
      update(accountConfigs).replace(config);

  Future<int> deleteAccountConfig(Insertable<AccountConfig> config) =>
      delete(accountConfigs).delete(config);

  // You can add more specific query methods here as needed.
  // For example:
  // Future<void> updateConfigDetails(int accountId, String newDetails) {
  //   return (update(accountConfigs)..where((tbl) => tbl.accountId.equals(accountId)))
  //       .write(AccountConfigsCompanion(configDetails: Value(newDetails)));
  // }
}
