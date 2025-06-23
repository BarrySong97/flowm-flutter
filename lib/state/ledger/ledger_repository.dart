import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/ledger_dao.dart';
import '../database/database_provider.dart';

/// 账本仓库提供者，用于封装账本相关的数据库操作
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final ledgerDao = ref.watch(ledgerDaoProvider);
  return LedgerRepository(db, ledgerDao);
});

/// 所有账本列表提供者，缓存获取的账本数据
final allLedgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getAllLedgers();
});

/// 账本监听流提供者，用于响应式更新UI
final watchAllLedgersProvider = StreamProvider<List<Ledger>>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.watchAllLedgers();
});

/// 选中账本提供者
final selectedLedgerProvider = StreamProvider<Ledger?>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.watchSelectedLedger();
});

/// 账本仓库类
///
/// 封装与账本相关的所有数据库操作，提供更高级别的业务逻辑方法
class LedgerRepository {
  final AppDatabase _db;
  final LedgerDao _ledgerDao;

  LedgerRepository(this._db, this._ledgerDao);

  /// 获取所有账本
  Future<List<Ledger>> getAllLedgers() => _ledgerDao.getAllLedgers();

  /// 监听所有账本（响应式流）
  Stream<List<Ledger>> watchAllLedgers() => _ledgerDao.watchAllLedgers();

  /// 根据ID获取账本
  Future<Ledger?> getLedgerById(int id) => _ledgerDao.getLedgerById(id);

  /// 获取当前选中的账本
  Future<Ledger?> getSelectedLedger() => _ledgerDao.getSelectedLedger();

  /// 监听选中的账本
  Stream<Ledger?> watchSelectedLedger() => _ledgerDao.watchSelectedLedger();

  /// 设置账本为选中状态
  Future<bool> setLedgerAsSelected(int id) => _ledgerDao.setLedgerSelected(id);

  /// 创建新账本
  Future<int> createLedger({
    required String name,
    String? description,
    bool isSelected = false,
    String? currencySymbol,
  }) async {
    final ledger = LedgersCompanion.insert(
      name: name,
      currencySymbol:
          currencySymbol == null ? const Value.absent() : Value(currencySymbol),
      description:
          description == null ? const Value.absent() : Value(description),
      createdAt: Value(DateTime.now()),
      isSelected: Value(isSelected),
    );

    final id = await _ledgerDao.insertLedger(ledger);

    // 如果新账本被设置为选中状态，确保其他账本设置为非选中状态
    if (isSelected && id > 0) {
      await _ledgerDao.setLedgerSelected(id);
    }

    return id;
  }

  /// 更新账本
  Future<bool> updateLedger({
    required int id,
    String? name,
    String? description,
    bool? isSelected,
    String? currencySymbol,
  }) async {
    final companion = LedgersCompanion(
      ledgerId: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
      currencySymbol:
          currencySymbol != null ? Value(currencySymbol) : const Value.absent(),
    );

    // 首先更新账本的非选中状态信息
    final updateSuccess = await _ledgerDao.updateLedger(companion);

    if (!updateSuccess) {
      return false;
    }

    // 如果 isSelected 被指定为 true，则调用 setLedgerSelected 来处理选中逻辑
    if (isSelected == true) {
      return _ledgerDao.setLedgerSelected(id);
    }

    return true;
  }

  /// 删除账本
  Future<int> deleteLedger(int id) => _ledgerDao.deleteLedger(id);

  /// 删除账本及其所有关联数据
  Future<void> deleteLedgerWithRelatedData(int ledgerId) async {
    // 检查是否为最后一个账本
    final allLedgers = await getAllLedgers();
    if (allLedgers.length <= 1) {
      throw Exception('无法删除最后一个账本，必须至少保留一个账本。');
    }

    await _db.transaction(() async {
      // 1. 找到所有与该账本关联的账户ID
      final accountsInLedger = await (_db.select(_db.accounts)
            ..where((tbl) => tbl.ledgerId.equals(ledgerId)))
          .get();
      final accountIds = accountsInLedger.map((a) => a.accountId).toList();

      if (accountIds.isNotEmpty) {
        // 2. 删除与这些账户关联的账户配置
        await (_db.delete(_db.accountConfigs)
              ..where((tbl) => tbl.accountId.isIn(accountIds)))
            .go();

        // 3. 找到所有与这些账户关联的 Posting，并获取唯一的交易ID
        final postings = await (_db.select(_db.postings)
              ..where((tbl) => tbl.accountId.isIn(accountIds)))
            .get();
        final transactionIds =
            postings.map((p) => p.transactionId).toSet().toList();

        if (transactionIds.isNotEmpty) {
          // 4. 删除与这些交易关联的交易标签
          await (_db.delete(_db.transactionTags)
                ..where((tbl) => tbl.transactionId.isIn(transactionIds)))
              .go();

          // 5. 删除与这些交易关联的分录 (postings)
          await (_db.delete(_db.postings)
                ..where((tbl) => tbl.transactionId.isIn(transactionIds)))
              .go();

          // 6. 删除交易本身
          await (_db.delete(_db.transactions)
                ..where((tbl) => tbl.transactionId.isIn(transactionIds)))
              .go();
        }
      }

      // 7. 删除账本下的所有账户
      await (_db.delete(_db.accounts)
            ..where((tbl) => tbl.ledgerId.equals(ledgerId)))
          .go();

      // 8. 最后删除账本自身
      await (_db.delete(_db.ledgers)
            ..where((tbl) => tbl.ledgerId.equals(ledgerId)))
          .go();
    });

    // 如果删除的是当前选中的账本，则选择另一个账本
    final selectedLedger = await getSelectedLedger();
    if (selectedLedger == null || selectedLedger.ledgerId == ledgerId) {
      final remainingLedgers = await getAllLedgers();
      if (remainingLedgers.isNotEmpty) {
        await setLedgerAsSelected(remainingLedgers.first.ledgerId);
      }
    }
  }
}
