import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get tagId => integer().autoIncrement()();
  TextColumn get tagName => text().unique()();
  TextColumn get displayColor => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
