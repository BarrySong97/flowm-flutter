import 'package:flowm/db/app_database.dart' show Account;
import 'package:flowm/db/dao/account_dao.dart';

class AccountCommandService {
  const AccountCommandService(this._accountDao);

  final AccountDao _accountDao;

  Future<List<Account>> getAllAccounts() {
    return _accountDao.getAllAccounts();
  }

  Future<Account?> getAccountById(int id) {
    return _accountDao.getAccountById(id);
  }

  Stream<List<Account>> watchAllAccounts() {
    return _accountDao.watchAllAccounts();
  }
}
