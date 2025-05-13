import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get accountId => integer().autoIncrement()();
  IntColumn get parentAccountId =>
      integer().nullable().references(Accounts, #accountId)();
  TextColumn get accountName => text()();
  TextColumn get fullPath => text()();
  TextColumn get accountType => textEnum<AccountType>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

enum AccountType { ASSET, LIABILITY, EQUITY, INCOME, EXPENSE }
