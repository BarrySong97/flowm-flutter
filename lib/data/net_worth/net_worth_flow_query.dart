import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/dao/posting_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';

class NetWorthFlowQuery {
  const NetWorthFlowQuery({
    required AccountDao accountDao,
    required PostingDao postingDao,
    required TransactionDao transactionDao,
  })  : _accountDao = accountDao,
        _postingDao = postingDao,
        _transactionDao = transactionDao;

  final AccountDao _accountDao;
  final PostingDao _postingDao;
  final TransactionDao _transactionDao;

  AccountDao get accountDao => _accountDao;
  PostingDao get postingDao => _postingDao;
  TransactionDao get transactionDao => _transactionDao;
}
