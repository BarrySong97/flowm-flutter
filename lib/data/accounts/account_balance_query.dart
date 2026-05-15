import 'package:drift/drift.dart';
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/tables/account_table.dart' show AccountType;

class AccountBalanceQuery {
  const AccountBalanceQuery(this._accountDao);

  final AccountDao _accountDao;

  Future<double> getAccountBalance(int accountId) {
    return _accountDao.getAccountBalance(accountId);
  }

  Future<Map<int, double>> getAccountBalances(List<int> accountIds) async {
    if (accountIds.isEmpty) return {};

    final placeholders = accountIds.map((_) => '?').join(',');
    final result = await _accountDao.customSelect(
      '''
      SELECT account_id, COALESCE(SUM(amount), 0) as balance
      FROM postings
      WHERE account_id IN ($placeholders)
      GROUP BY account_id
      ''',
      variables: accountIds.map((id) => Variable.withInt(id)).toList(),
    ).get();

    return {
      for (final row in result)
        row.read<int>('account_id'): row.read<double>('balance')
    };
  }

  Future<List<AccountWithBalance>> getTopAssetAccountsByLedger({
    required int ledgerId,
    int? limit,
  }) async {
    return getTopAccountsByLedger(
      ledgerId: ledgerId,
      accountType: AccountType.ASSET,
      limit: limit,
      leafOnly: true,
    );
  }

  Future<List<AccountWithBalance>> getTopAccountsByLedger({
    required int ledgerId,
    required AccountType accountType,
    int? limit,
    bool leafOnly = false,
    bool absoluteBalance = false,
  }) async {
    final accounts = (await _accountDao.getAccountsByLedgerId(ledgerId))
        .where((account) => account.accountType == accountType)
        .where((account) => account.isActive)
        .toList();

    final accountsWithChildren = accounts
        .where((account) => account.parentAccountId != null)
        .map((account) => account.parentAccountId!)
        .toSet();

    final selectedAccounts = leafOnly
        ? accounts
            .where(
                (account) => !accountsWithChildren.contains(account.accountId))
            .toList()
        : accounts;

    final balances = await getAccountBalances(
      selectedAccounts.map((account) => account.accountId).toList(),
    );

    final accountsWithBalance = selectedAccounts
        .map((account) => AccountWithBalance(
              account: account,
              balance: absoluteBalance
                  ? (balances[account.accountId] ?? 0.0).abs()
                  : balances[account.accountId] ?? 0.0,
            ))
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    return limit != null
        ? accountsWithBalance.take(limit).toList()
        : accountsWithBalance;
  }
}
