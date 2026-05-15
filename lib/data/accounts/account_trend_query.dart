import 'package:flowm/data/accounts/account_balance_query.dart';

class AccountTrendQuery {
  const AccountTrendQuery(this._balanceQuery);

  final AccountBalanceQuery _balanceQuery;

  AccountBalanceQuery get balanceQuery => _balanceQuery;
}
