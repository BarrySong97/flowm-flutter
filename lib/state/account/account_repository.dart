import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/account_dao.dart';
import '../../db/tables/account_table.dart';
import '../database/database_provider.dart';

/// 账户仓库提供者，用于封装账户相关的数据库操作
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  return AccountRepository(accountDao);
});

/// 账户仓库类
///
/// 封装与账户相关的所有数据库操作，提供更高级别的业务逻辑方法
class AccountRepository {
  final AccountDao _accountDao;

  AccountRepository(this._accountDao);

  /// 获取所有账户
  Future<List<Account>> getAllAccounts() => _accountDao.getAllAccounts();

  /// 监听所有账户（响应式流）
  Stream<List<Account>> watchAllAccounts() => _accountDao.watchAllAccounts();

  /// 根据账户类型获取账户
  Stream<List<Account>> watchAccountsByType(AccountType type) =>
      _accountDao.watchAccountsByType(type);

  /// 获取账户详情
  Future<Account?> getAccountById(int id) => _accountDao.getAccountById(id);

  /// 获取所有叶子资产账户（按余额降序排序）
  Future<List<AccountWithBalance>> getTopAssetAccounts({int? limit}) =>
      _accountDao.getTopAssetAccounts(limit: limit);

  /// 创建新账户
  Future<int> createAccount({
    required String name,
    required String fullPath,
    required AccountType type,
    int? parentId,
    bool isActive = true,
  }) {
    return _accountDao.insertAccount(AccountsCompanion.insert(
      accountName: name,
      fullPath: fullPath,
      accountType: type,
      parentAccountId:
          parentId == null ? const Value.absent() : Value(parentId),
      isActive: Value(isActive),
    ));
  }

  /// 更新账户
  Future<bool> updateAccount({
    required int id,
    String? name,
    AccountType? type,
    bool? isActive,
  }) {
    return _accountDao.updateAccount(AccountsCompanion(
      accountId: Value(id),
      accountName: name != null ? Value(name) : const Value.absent(),
      accountType: type != null ? Value(type) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
    ));
  }

  /// 删除账户
  Future<bool> deleteAccount(int id) async {
    // 检查是否有子账户
    final children = await _accountDao.getChildAccounts(id);
    if (children.isNotEmpty) {
      // 如果有子账户，不允许删除
      return false;
    }

    // 没有子账户，执行删除
    final result = await _accountDao.deleteAccount(id);
    return result > 0;
  }

  /// 获取账户树
  ///
  /// 返回一个包含所有顶级账户及其子账户的嵌套结构
  Future<List<AccountWithChildren>> getAccountTree() async {
    // 获取所有账户
    final allAccounts = await _accountDao.getAllAccounts();

    // 找出顶级账户（没有父账户的账户）
    final rootAccounts = allAccounts
        .where((account) => account.parentAccountId == null)
        .toList();

    // 递归构建账户树
    return rootAccounts.map((root) {
      return _buildAccountTree(root, allAccounts);
    }).toList();
  }

  // 递归构建账户树的辅助方法
  AccountWithChildren _buildAccountTree(
      Account root, List<Account> allAccounts) {
    final children = allAccounts
        .where((account) => account.parentAccountId == root.accountId)
        .map((child) => _buildAccountTree(child, allAccounts))
        .toList();

    return AccountWithChildren(account: root, children: children);
  }
}

/// 带有子账户的账户模型
class AccountWithChildren {
  final Account account;
  final List<AccountWithChildren> children;

  AccountWithChildren({required this.account, required this.children});
}
