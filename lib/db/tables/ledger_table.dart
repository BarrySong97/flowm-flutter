import 'package:drift/drift.dart';

@DataClassName('Ledger')
class Ledgers extends Table {
  IntColumn get ledgerId => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSelected => boolean().withDefault(const Constant(false))();
  TextColumn get currencySymbol => text().withDefault(const Constant('¥'))();
}
