import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get transactionId => integer().autoIncrement()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
