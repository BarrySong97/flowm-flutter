import 'package:drift/drift.dart';
import 'account_table.dart'; // Import the Accounts table

//drift_docs: https://drift.simonbinder.eu/docs/getting-started/work_with_tables/
//drift_docs: https://drift.simonbinder.eu/docs/advanced-features/joins/#setting-up-relationships
//drift_docs: https://drift.simonbinder.eu/docs/getting-started/work_with_tables/#primary-keys

/// Represents the configuration settings for an account.
/// This table has a one-to-one relationship with the [Accounts] table.
class AccountConfigs extends Table {
  /// The ID of the account this configuration belongs to.
  /// This is also the primary key for this table and a foreign key to [Accounts.accountId].
  IntColumn get accountId => integer().references(Accounts, #accountId)();

  /// Example configuration data column.
  /// You can replace this with actual configuration fields.
  TextColumn get configDetails => text().nullable()();

  /// Timestamp of when the configuration was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp of when the configuration was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {accountId};
}

// You might want to add specific configuration fields above instead of a generic configDetails.
// For example:
// BoolColumn get enableNotifications => boolean().withDefault(const Constant(true))();
// TextColumn get preferredTheme => text().nullable()();
