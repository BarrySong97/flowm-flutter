import 'package:drift/drift.dart';
import 'transaction_table.dart';
import 'account_table.dart';

class Postings extends Table {
  IntColumn get postingId => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #transactionId)();
  IntColumn get accountId => integer().references(Accounts, #accountId)();
  RealColumn get amount => real()();
  TextColumn get postingTag => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
