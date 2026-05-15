import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/ledger_dao.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../database/database_provider.dart';

/// 账本仓库提供者，用于封装账本相关的数据库操作
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final ledgerDao = ref.watch(ledgerDaoProvider);
  final accountDao = ref.watch(accountDaoProvider);
  return LedgerRepository(db, ledgerDao, accountDao);
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
  final AccountDao _accountDao;

  LedgerRepository(this._db, this._ledgerDao, this._accountDao);

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
    // 在创建新账本前，先获取当前选中的账本作为复制源
    final sourceLedgerToCopy = await getSelectedLedger();

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

    // 为新账本初始化账户
    if (id > 0) {
      await _initializeAccountsForNewLedger(id, sourceLedgerToCopy);
    }

    return id;
  }

  /// 为新账本初始化账户。
  /// 优先从源账本复制账户结构，如果源账本不存在（如创建第一个账本时），
  /// 则创建一套默认账户。
  Future<void> _initializeAccountsForNewLedger(
      int newLedgerId, Ledger? sourceLedger) async {
    if (sourceLedger == null) {
      // 如果没有源账本，则创建默认账户
      await _createDefaultAccounts(newLedgerId);
      return;
    }

    final sourceAccounts =
        await _accountDao.getAccountsByLedgerId(sourceLedger.ledgerId);
    if (sourceAccounts.isEmpty) {
      // 源账本没有账户，直接返回
      return;
    }

    // 按一级账户ID对源账户进行分组，以便按层级复制
    final Map<int?, List<Account>> accountsByParent = {};
    for (final acc in sourceAccounts) {
      (accountsByParent[acc.parentAccountId] ??= []).add(acc);
    }

    // 递归复制账户
    await _recursivelyCopyAccounts(
      oldParentId: null,
      newParentId: null,
      parentFullPath: '',
      newLedgerId: newLedgerId,
      accountsByParent: accountsByParent,
      oldToNewAccountIdMap: {},
    );
  }

  /// 递归地复制账户，以保持其层级结构。
  Future<void> _recursivelyCopyAccounts({
    required int? oldParentId,
    required int? newParentId,
    required String parentFullPath,
    required int newLedgerId,
    required Map<int?, List<Account>> accountsByParent,
    required Map<int, int> oldToNewAccountIdMap,
  }) async {
    final childrenToCopy = accountsByParent[oldParentId];
    if (childrenToCopy == null || childrenToCopy.isEmpty) {
      return;
    }

    for (final sourceAccount in childrenToCopy) {
      // 重新生成新的 fullPath
      final newFullPath = parentFullPath.isEmpty
          ? sourceAccount.accountName
          : '$parentFullPath:${sourceAccount.accountName}';

      final newAccountCompanion = AccountsCompanion.insert(
        ledgerId: newLedgerId,
        parentAccountId:
            newParentId == null ? const Value.absent() : Value(newParentId),
        accountName: sourceAccount.accountName,
        fullPath: newFullPath,
        accountType: sourceAccount.accountType,
        isActive: Value(sourceAccount.isActive),
      );

      final newAccountId = await _accountDao.insertAccount(newAccountCompanion);
      oldToNewAccountIdMap[sourceAccount.accountId] = newAccountId;

      // 为子账户递归调用
      await _recursivelyCopyAccounts(
        oldParentId: sourceAccount.accountId,
        newParentId: newAccountId,
        parentFullPath: newFullPath,
        newLedgerId: newLedgerId,
        accountsByParent: accountsByParent,
        oldToNewAccountIdMap: oldToNewAccountIdMap,
      );
    }
  }

  /// 为新账本创建一套默认的账户结构（仅在无法复制时作为后备方案）。
  Future<void> _createDefaultAccounts(int ledgerId) async {
    // 资产账户
    final currentAssetsId = await _createAccount(
      ledgerId,
      null,
      '流动资产',
      '资产:流动资产',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      currentAssetsId,
      '现金',
      '资产:流动资产:现金',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      currentAssetsId,
      '银行存款',
      '资产:流动资产:银行存款',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      currentAssetsId,
      '支付宝',
      '资产:流动资产:支付宝',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      currentAssetsId,
      '微信支付',
      '资产:流动资产:微信支付',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      currentAssetsId,
      '应收账款',
      '资产:流动资产:应收账款',
      AccountType.ASSET,
    );

    // 固定资产
    final fixedAssetsId = await _createAccount(
      ledgerId,
      null,
      '固定资产',
      '资产:固定资产',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      fixedAssetsId,
      '房产',
      '资产:固定资产:房产',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      fixedAssetsId,
      '车辆',
      '资产:固定资产:车辆',
      AccountType.ASSET,
    );

    await _createAccount(
      ledgerId,
      fixedAssetsId,
      '电子设备',
      '资产:固定资产:电子设备',
      AccountType.ASSET,
    );

    // 负债账户
    final shortTermLiabilityId = await _createAccount(
      ledgerId,
      null,
      '流动负债',
      '负债:流动负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      shortTermLiabilityId,
      '信用卡',
      '负债:流动负债:信用卡',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      shortTermLiabilityId,
      '花呗',
      '负债:流动负债:花呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      shortTermLiabilityId,
      '白条',
      '负债:流动负债:白条',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      shortTermLiabilityId,
      '借呗',
      '负债:流动负债:借呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      shortTermLiabilityId,
      '应付账款',
      '负债:流动负债:应付账款',
      AccountType.LIABILITY,
    );

    final longTermLiabilityId = await _createAccount(
      ledgerId,
      null,
      '长期负债',
      '负债:长期负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      longTermLiabilityId,
      '房贷',
      '负债:长期负债:房贷',
      AccountType.LIABILITY,
    );

    await _createAccount(
      ledgerId,
      longTermLiabilityId,
      '车贷',
      '负债:长期负债:车贷',
      AccountType.LIABILITY,
    );

    // 权益账户
    await _createAccount(
      ledgerId,
      null,
      '个人资本',
      '所有者权益:个人资本',
      AccountType.EQUITY,
    );

    await _createAccount(
      ledgerId,
      null,
      '期初余额',
      '所有者权益:期初余额',
      AccountType.EQUITY,
    );

    // 收入账户
    await _createAccount(
      ledgerId,
      null,
      '工资收入',
      '收入:工资收入',
      AccountType.INCOME,
    );

    await _createAccount(
      ledgerId,
      null,
      '奖金收入',
      '收入:奖金收入',
      AccountType.INCOME,
    );

    await _createAccount(
      ledgerId,
      null,
      '投资收益',
      '收入:投资收益',
      AccountType.INCOME,
    );

    await _createAccount(
      ledgerId,
      null,
      '理财收益',
      '收入:理财收益',
      AccountType.INCOME,
    );

    await _createAccount(
      ledgerId,
      null,
      '兼职收入',
      '收入:兼职收入',
      AccountType.INCOME,
    );

    await _createAccount(
      ledgerId,
      null,
      '其他收入',
      '收入:其他收入',
      AccountType.INCOME,
    );

    // 支出账户
    final dailyExpensesId = await _createAccount(
      ledgerId,
      null,
      '日常支出',
      '支出:日常支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      dailyExpensesId,
      '餐饮',
      '支出:日常支出:餐饮',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      dailyExpensesId,
      '购物',
      '支出:日常支出:购物',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      dailyExpensesId,
      '交通',
      '支出:日常支出:交通',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      dailyExpensesId,
      '娱乐',
      '支出:日常支出:娱乐',
      AccountType.EXPENSE,
    );

    final housingExpensesId = await _createAccount(
      ledgerId,
      null,
      '住房支出',
      '支出:住房支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      housingExpensesId,
      '房租',
      '支出:住房支出:房租',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      housingExpensesId,
      '物业费',
      '支出:住房支出:物业费',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      housingExpensesId,
      '水电煤',
      '支出:住房支出:水电煤',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      null,
      '通讯',
      '支出:通讯',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      null,
      '医疗',
      '支出:医疗',
      AccountType.EXPENSE,
    );

    await _createAccount(
      ledgerId,
      null,
      '教育',
      '支出:教育',
      AccountType.EXPENSE,
    );
  }

  /// 创建账户的辅助方法
  Future<int> _createAccount(
    int ledgerId,
    int? parentId,
    String name,
    String fullPath,
    AccountType type,
  ) async {
    return await _accountDao.insertAccount(
      AccountsCompanion.insert(
        ledgerId: ledgerId,
        parentAccountId:
            parentId != null ? Value(parentId) : const Value.absent(),
        accountName: name,
        fullPath: fullPath,
        accountType: type,
      ),
    );
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
