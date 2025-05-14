import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/account_table.dart';
import '../tables/posting_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(AppDatabase db) : super(db);

  // Get all accounts
  Future<List<Account>> getAllAccounts() => select(accounts).get();

  // Get account by ID
  Future<Account?> getAccountById(int id) =>
      (select(accounts)..where((a) => a.accountId.equals(id)))
          .getSingleOrNull();

  // Watch all accounts (reactive stream)
  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  // Watch accounts by type
  Stream<List<Account>> watchAccountsByType(AccountType type) =>
      (select(accounts)..where((a) => a.accountType.equals(type.name))).watch();

  // Insert account
  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  // Update account
  Future<bool> updateAccount(AccountsCompanion account) =>
      update(accounts).replace(account);

  // Delete account
  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.accountId.equals(id))).go();

  // Get child accounts
  Future<List<Account>> getChildAccounts(int parentId) =>
      (select(accounts)..where((a) => a.parentAccountId.equals(parentId)))
          .get();

  // Get account balance by account ID from postings table
  Future<double> getAccountBalance(int accountId) async {
    final result = await customSelect(
      'SELECT SUM(amount) as balance FROM postings WHERE account_id = ?',
      variables: [Variable.withInt(accountId)],
    ).getSingle();

    return result.read<double?>('balance') ?? 0.0;
  }

  // Get all leaf asset accounts by balance in descending order
  Future<List<AccountWithBalance>> getTopAssetAccounts({int? limit}) async {
    // 先获取所有活跃的资产账户
    final assetAccounts = await (select(accounts)
          ..where((a) => a.accountType.equals(AccountType.ASSET.name))
          ..where((a) => a.isActive.equals(true)))
        .get();

    // 获取所有具有子账户的账户ID
    final accountsWithChildren = await customSelect(
      'SELECT DISTINCT parent_account_id FROM accounts WHERE parent_account_id IS NOT NULL',
    ).get().then((rows) =>
        rows.map((row) => row.read<int>('parent_account_id')).toSet());

    // 过滤掉有子账户的账户，只保留叶子节点账户
    final leafAccounts = assetAccounts
        .where((account) => !accountsWithChildren.contains(account.accountId))
        .toList();

    // 计算每个账户的余额
    final List<AccountWithBalance> accountsWithBalance = [];

    for (final account in leafAccounts) {
      // 使用getAccountBalance方法获取账户余额
      final balance = await getAccountBalance(account.accountId);

      accountsWithBalance.add(
        AccountWithBalance(
          account: account,
          balance: balance,
        ),
      );
    }

    // 按余额降序排序
    accountsWithBalance.sort((a, b) => b.balance.compareTo(a.balance));

    // 如果指定了limit，则返回前limit个，否则返回全部
    return limit != null
        ? accountsWithBalance.take(limit).toList()
        : accountsWithBalance;
  }

  // Calculate total liabilities
  Future<double> getTotalLiabilities() async {
    // Get all active liability accounts
    final liabilityAccounts = await (select(accounts)
          ..where((a) => a.accountType.equals(AccountType.LIABILITY.name))
          ..where((a) => a.isActive.equals(true)))
        .get();

    double totalLiabilities = 0.0;

    // Calculate balance for each liability account and sum them up
    for (final account in liabilityAccounts) {
      final balance = await getAccountBalance(account.accountId);
      totalLiabilities += balance;
    }

    return totalLiabilities;
  }
}

// Class to hold account with its calculated balance
class AccountWithBalance {
  final Account account;
  final double balance;

  AccountWithBalance({
    required this.account,
    required this.balance,
  });
}
