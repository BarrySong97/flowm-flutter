import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ledger_table.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [Ledgers])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  Future<List<Ledger>> getAllLedgers() => select(ledgers).get();

  Stream<List<Ledger>> watchAllLedgers() => select(ledgers).watch();

  Future<Ledger?> getLedgerById(int id) =>
      (select(ledgers)..where((l) => l.ledgerId.equals(id))).getSingleOrNull();

  Future<int> insertLedger(LedgersCompanion ledger) =>
      into(ledgers).insert(ledger);

  Future<bool> updateLedger(LedgersCompanion ledger) =>
      update(ledgers).replace(ledger);

  Future<int> deleteLedger(int id) =>
      (delete(ledgers)..where((l) => l.ledgerId.equals(id))).go();

  /// 获取当前选中的账本
  Future<Ledger?> getSelectedLedger() =>
      (select(ledgers)..where((l) => l.isSelected.equals(true)))
          .getSingleOrNull();

  /// 设置账本为选中状态
  Future<bool> setLedgerSelected(int id) async {
    // 开启事务
    return transaction(() async {
      // 先将所有账本设置为未选中
      await (update(ledgers)..where((l) => l.isSelected.equals(true)))
          .write(const LedgersCompanion(isSelected: Value(false)));

      // 再将指定账本设置为选中
      final result = await (update(ledgers)
            ..where((l) => l.ledgerId.equals(id)))
          .write(const LedgersCompanion(isSelected: Value(true)));

      return result > 0;
    });
  }

  /// 监听选中的账本
  Stream<Ledger?> watchSelectedLedger() =>
      (select(ledgers)..where((l) => l.isSelected.equals(true)))
          .watchSingleOrNull();
}
