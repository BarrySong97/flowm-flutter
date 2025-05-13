# Financial Database Structure (Drift Implementation)

This directory contains the Drift implementation of a financial management database, converted from a Drizzle ORM schema.

## Database Structure

### Tables

1. **Accounts (`accounts`)**

   - Core entity for tracking financial accounts
   - Supports hierarchical account structure with parent-child relationships
   - Account types: ASSET, LIABILITY, EQUITY, INCOME, EXPENSE

2. **Transactions (`transactions`)**

   - Records financial transactions
   - Each transaction can have multiple postings and tags

3. **Postings (`postings`)**

   - Entries that connect transactions to accounts
   - Each posting represents a debit or credit to a specific account

4. **Tags (`tags`)**

   - Provides categorization for transactions
   - Includes display color for UI presentation

5. **Transaction Tags (`transaction_tags`)**
   - Junction table linking transactions to tags
   - Implements many-to-many relationship

## Implementation Details

### Table Definitions

Located in `lib/db/tables/`:

- `account_table.dart`
- `transaction_table.dart`
- `posting_table.dart`
- `tag_table.dart`
- `transaction_tag_table.dart`

### Data Access Objects (DAOs)

Located in `lib/db/dao/`:

- `account_dao.dart`
- `transaction_dao.dart`
- `posting_dao.dart`
- `tag_dao.dart`
- `transaction_tag_dao.dart`

### Database Configuration

- Main database definition in `lib/db/app_database.dart`
- Version control and migrations handled through Drift's schema versioning

## Usage

1. Make sure to add Drift to your dependencies:

   ```yaml
   dependencies:
     drift: ^[latest_version]
     sqlite3_flutter_libs: ^[latest_version]
     path_provider: ^[latest_version]
     path: ^[latest_version]

   dev_dependencies:
     drift_dev: ^[latest_version]
     build_runner: ^[latest_version]
   ```

2. Generate Drift code:

   ```
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Access database through the AppDatabase class and DAOs:
   ```dart
   final database = AppDatabase();
   final accountDao = database.accountDao;
   final transactionDao = database.transactionDao;
   // ...
   ```

## Note on Data Types

This Drift implementation converts from Drizzle ORM with the following type mappings:

| Drizzle Type                            | Drift Type                            |
| --------------------------------------- | ------------------------------------- |
| `int('id').primaryKey()`                | `integer().autoIncrement()()`         |
| `int('is_active', { mode: 'boolean' })` | `boolean()()`                         |
| `int('date', { mode: 'timestamp' })`    | `dateTime()()`                        |
| `text('name')`                          | `text()()`                            |
| `real('amount')`                        | `real()()`                            |
| Foreign keys                            | `references(Table, #column)()`        |
| Composite primary keys                  | `override Set<Column> get primaryKey` |

## Seed Data

The database includes seed data for initializing a double-entry accounting system with accounts and sample transactions suitable for the Chinese market.

To use the seed data, import `seed_data.dart` and call the following:

```dart
final db = AppDatabase();
final seedData = SeedData(db);
await seedData.seedDatabase();
```

The seed data includes:

1. Account Structure:

   - Asset accounts: 流动资产 (现金, 银行存款, 支付宝, 微信支付, 应收账款) and 固定资产 (房产, 车辆, 电子设备)
   - Liability accounts: 流动负债 (信用卡, 花呗, 借呗, 应付账款) and 长期负债 (房贷, 车贷)
   - Equity accounts: 个人资本, 期初余额
   - Income accounts: 工资收入, 奖金收入, 投资收益, 理财收益, 兼职收入, 其他收入
   - Expense accounts: 日常支出 (餐饮, 购物, 交通, 娱乐), 住房支出 (房租, 物业费, 水电煤), 通讯, 医疗, 教育, 保险, 税费

2. Sample Transactions:
   - Initial balance with assets and liabilities
   - Salary income
   - Restaurant expense
   - Grocery shopping
   - Utilities payment
   - Transportation expense
   - Credit card payment

All transactions follow double-entry accounting principles with balanced debits and credits.
