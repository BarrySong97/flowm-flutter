import 'package:drift/drift.dart';
import 'ledger_table.dart'; // Added import for Ledgers table

class Accounts extends Table {
  IntColumn get accountId => integer().autoIncrement()();
  IntColumn get ledgerId => integer().references(Ledgers, #ledgerId)();
  IntColumn get parentAccountId =>
      integer().nullable().references(Accounts, #accountId)();
  TextColumn get accountName => text()();
  TextColumn get fullPath => text()();
  TextColumn get accountType => textEnum<AccountType>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get defaultUseAssets => boolean().nullable().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

enum AccountType { ASSET, LIABILITY, EQUITY, INCOME, EXPENSE }
