import 'package:drift/drift.dart';
import 'transaction_table.dart';
import 'tag_table.dart';

class TransactionTags extends Table {
  IntColumn get transactionId =>
      integer().references(Transactions, #transactionId)();
  IntColumn get tagId => integer().references(Tags, #tagId)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}
