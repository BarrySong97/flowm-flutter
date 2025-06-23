import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/ledger_dao.dart';
import '../database/database_provider.dart';

/// 账本仓库提供者，用于封装账本相关的数据库操作
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final ledgerDao = ref.watch(ledgerDaoProvider);
  return LedgerRepository(ledgerDao);
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
  final LedgerDao _ledgerDao;

  LedgerRepository(this._ledgerDao);

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
}
