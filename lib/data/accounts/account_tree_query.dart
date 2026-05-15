import 'package:flowm/db/app_database.dart' show Account;
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/data/accounts/account_balance_query.dart';
import 'package:flowm/domain/accounts/account_models.dart';

class AccountTreeQuery {
  const AccountTreeQuery(this._accountDao, this._balanceQuery);

  final AccountDao _accountDao;
  final AccountBalanceQuery _balanceQuery;

  Future<List<AccountTreeNode>> getAccountTree({
    required AccountTreeType type,
    required int ledgerId,
    int? parentId,
  }) async {
    final rawTree = await _getAccountTree(
      ledgerId: ledgerId,
      parentId: parentId,
      type: type.accountType,
    );
    return _toNodes(rawTree);
  }

  Stream<List<AccountTreeNode>> watchAccountTree({
    required AccountTreeType type,
    int? ledgerId,
  }) {
    return _accountDao
        .watchAccountsByType(type.accountType)
        .asyncMap((_) async {
      final rawTree = await _getAccountTree(
        ledgerId: ledgerId,
        type: type.accountType,
      );
      return _toNodes(rawTree);
    });
  }

  Stream<List<Account>> watchAccountsByType(AccountType type) {
    return _accountDao.watchAccountsByType(type);
  }

  Future<List<RawAccountTreeNode>> _getAccountTree({
    required AccountType type,
    int? ledgerId,
    int? parentId,
  }) async {
    final allAccounts = await _accountDao.getAccountsByLedgerId(ledgerId ?? 0);
    final filteredAccounts =
        allAccounts.where((account) => account.accountType == type).toList();
    final rootAccounts = filteredAccounts
        .where((account) => account.parentAccountId == parentId)
        .toList();

    return rootAccounts
        .map((root) => _buildRawAccountTree(root, filteredAccounts))
        .toList();
  }

  RawAccountTreeNode _buildRawAccountTree(
      Account root, List<Account> accounts) {
    final children = accounts
        .where((account) => account.parentAccountId == root.accountId)
        .map((child) => _buildRawAccountTree(child, accounts))
        .toList();

    return RawAccountTreeNode(account: root, children: children);
  }

  Future<List<AccountTreeNode>> _toNodes(
    List<RawAccountTreeNode> accounts,
  ) async {
    final accountIds = <int>{};
    void collect(List<RawAccountTreeNode> nodes) {
      for (final node in nodes) {
        accountIds.add(node.account.accountId);
        collect(node.children);
      }
    }

    collect(accounts);
    final balances =
        await _balanceQuery.getAccountBalances(accountIds.toList());
    return _toNodesWithBalances(accounts, balances);
  }

  List<AccountTreeNode> _toNodesWithBalances(
    List<RawAccountTreeNode> accounts,
    Map<int, double> balances,
  ) {
    return accounts.map((accountWithChildren) {
      final children =
          _toNodesWithBalances(accountWithChildren.children, balances);
      final childrenBalance = children.fold<double>(
        0,
        (total, child) => total + child.balance,
      );
      final directBalance =
          balances[accountWithChildren.account.accountId] ?? 0;
      return AccountTreeNode(
        account: accountWithChildren.account,
        balance: directBalance + childrenBalance,
        children: children,
      );
    }).toList();
  }
}
