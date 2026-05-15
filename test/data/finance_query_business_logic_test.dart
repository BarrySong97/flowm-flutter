import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flowm/data/accounts/account_balance_query.dart';
import 'package:flowm/data/accounts/account_tree_query.dart';
import 'package:flowm/db/app_database.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/domain/accounts/account_models.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/liabilities/liabilities_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('finance query business logic', () {
    test('returns active leaf asset accounts by ledger ordered by balance',
        () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final otherLedgerId = await _insertLedger(db, 'Other');

      final assetsId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Assets',
        type: AccountType.ASSET,
      );
      final checkingId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: assetsId,
        name: 'Checking',
        type: AccountType.ASSET,
      );
      final savingsId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: assetsId,
        name: 'Savings',
        type: AccountType.ASSET,
      );
      final inactiveId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Inactive',
        type: AccountType.ASSET,
        isActive: false,
      );
      final otherLedgerAssetId = await _insertAccount(
        db,
        ledgerId: otherLedgerId,
        name: 'Other Ledger Cash',
        type: AccountType.ASSET,
      );

      final transactionId = await _insertTransaction(db, DateTime(2026, 5));
      await _insertPosting(db, transactionId, checkingId, 100);
      await _insertPosting(db, transactionId, savingsId, 300);
      await _insertPosting(db, transactionId, assetsId, 999);
      await _insertPosting(db, transactionId, inactiveId, 500);
      await _insertPosting(db, transactionId, otherLedgerAssetId, 1000);

      final query = AccountBalanceQuery(db.accountDao);
      final accounts =
          await query.getTopAssetAccountsByLedger(ledgerId: ledgerId);

      expect(accounts.map((item) => item.account.accountId),
          [savingsId, checkingId]);
      expect(accounts.map((item) => item.balance), [300, 100]);

      final limited =
          await query.getTopAssetAccountsByLedger(ledgerId: ledgerId, limit: 1);
      expect(limited.single.account.accountId, savingsId);
    });

    test('rolls child balances into the requested account tree type', () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final otherLedgerId = await _insertLedger(db, 'Other');

      final expenseParentId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Food',
        type: AccountType.EXPENSE,
      );
      final expenseChildId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: expenseParentId,
        name: 'Dining',
        type: AccountType.EXPENSE,
      );
      final incomeId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Salary',
        type: AccountType.INCOME,
      );
      final otherLedgerExpenseId = await _insertAccount(
        db,
        ledgerId: otherLedgerId,
        name: 'Other Food',
        type: AccountType.EXPENSE,
      );

      final transactionId = await _insertTransaction(db, DateTime(2026, 5, 1));
      await _insertPosting(db, transactionId, expenseParentId, 10);
      await _insertPosting(db, transactionId, expenseChildId, 25);
      await _insertPosting(db, transactionId, incomeId, -100);
      await _insertPosting(db, transactionId, otherLedgerExpenseId, 1000);

      final query =
          AccountTreeQuery(db.accountDao, AccountBalanceQuery(db.accountDao));
      final tree = await query.getAccountTree(
        type: AccountTreeType.expense,
        ledgerId: ledgerId,
      );

      expect(tree, hasLength(1));
      expect(tree.single.account.accountId, expenseParentId);
      expect(tree.single.balance, 35);
      expect(tree.single.children, hasLength(1));
      expect(tree.single.children.single.account.accountId, expenseChildId);
      expect(tree.single.children.single.balance, 25);
    });

    test('repository APIs preserve income and expense sign rules', () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final expenseId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Food',
        type: AccountType.EXPENSE,
      );
      final liabilityId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Credit Card',
        type: AccountType.LIABILITY,
      );
      final incomeId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Salary',
        type: AccountType.INCOME,
      );

      final firstDay = await _insertTransaction(db, DateTime(2026, 5, 1, 10));
      await _insertPosting(db, firstDay, expenseId, 40);
      await _insertPosting(db, firstDay, liabilityId, 15);
      await _insertPosting(db, firstDay, incomeId, -100);
      await _insertPosting(db, firstDay, incomeId, 25);

      final outsideRange =
          await _insertTransaction(db, DateTime(2026, 5, 3, 10));
      await _insertPosting(db, outsideRange, expenseId, 999);
      await _insertPosting(db, outsideRange, incomeId, -999);

      final expenseRepository = ExpenseRepository(db.postingDao);
      final incomeRepository = IncomeRepository(db.postingDao);
      final startDate = DateTime(2026, 5, 1);
      final endDate = DateTime(2026, 5, 2);

      final expenseChart = await expenseRepository.getExpenseChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );
      final incomeChart = await incomeRepository.getIncomeChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );

      expect(expenseChart.map((point) => point.day), ['5/1', '5/2']);
      expect(expenseChart.map((point) => point.y), [55, 0]);
      expect(incomeChart.map((point) => point.day), ['5/1', '5/2']);
      expect(incomeChart.map((point) => point.y), [100, 0]);

      expect(
        await expenseRepository.getAccountExpenseBalance(
          accountId: expenseId,
          startDate: startDate,
          endDate: endDate,
        ),
        40,
      );
      expect(
        await incomeRepository.getAccountIncomeBalance(
          accountId: incomeId,
          startDate: startDate,
          endDate: endDate,
        ),
        100,
      );
    });

    test('repository account trees aggregate children and percentages',
        () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final expenseParentId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Food',
        type: AccountType.EXPENSE,
      );
      final expenseChildId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: expenseParentId,
        name: 'Dining',
        type: AccountType.EXPENSE,
      );
      final incomeParentId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Work',
        type: AccountType.INCOME,
      );
      final incomeChildId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: incomeParentId,
        name: 'Salary',
        type: AccountType.INCOME,
      );

      final transactionId = await _insertTransaction(db, DateTime(2026, 5, 1));
      await _insertPosting(db, transactionId, expenseParentId, 10);
      await _insertPosting(db, transactionId, expenseChildId, 30);
      await _insertPosting(db, transactionId, incomeChildId, -120);

      final expenseTree = await ExpenseRepository(db.postingDao)
          .getExpenseAccountTree(
              startDate: DateTime(2026, 5, 1),
              endDate: DateTime(2026, 5, 2),
              ledgerId: ledgerId);
      final incomeTree = await IncomeRepository(db.postingDao)
          .getIncomeAccountTree(
              startDate: DateTime(2026, 5, 1),
              endDate: DateTime(2026, 5, 2),
              ledgerId: ledgerId);

      expect(expenseTree.single.accountData.accountId, expenseParentId);
      expect(expenseTree.single.balance, 40);
      expect(expenseTree.single.percentage, 100);
      expect(expenseTree.single.children.single.accountData.accountId,
          expenseChildId);
      expect(expenseTree.single.children.single.balance, 30);
      expect(expenseTree.single.children.single.percentage, 75);

      expect(incomeTree.single.accountData.accountId, incomeParentId);
      expect(incomeTree.single.balance, 120);
      expect(incomeTree.single.percentage, 100);
      expect(incomeTree.single.children.single.accountData.accountId,
          incomeChildId);
      expect(incomeTree.single.children.single.balance, 120);
      expect(incomeTree.single.children.single.percentage, 100);
    });

    test('account repository tree APIs preserve old interface semantics',
        () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final otherLedgerId = await _insertLedger(db, 'Other');

      final assetsId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Assets',
        type: AccountType.ASSET,
      );
      final checkingId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: assetsId,
        name: 'Checking',
        type: AccountType.ASSET,
      );
      final savingsId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        parentAccountId: assetsId,
        name: 'Savings',
        type: AccountType.ASSET,
      );
      final otherLedgerAssetId = await _insertAccount(
        db,
        ledgerId: otherLedgerId,
        name: 'Other Cash',
        type: AccountType.ASSET,
      );

      final transactionId = await _insertTransaction(db, DateTime(2026, 5, 1));
      await _insertPosting(db, transactionId, assetsId, 5);
      await _insertPosting(db, transactionId, checkingId, 100);
      await _insertPosting(db, transactionId, savingsId, 300);
      await _insertPosting(db, transactionId, otherLedgerAssetId, 1000);

      final repository = AccountRepository(db.accountDao, db.transactionDao);

      final assetTree = await repository.getAssetsAccountTree(
        ledgerId: ledgerId,
        currencySymbol: '\$',
      );
      expect(assetTree, hasLength(1));
      expect(assetTree.single.id, assetsId);
      expect(assetTree.single.amount, 405);
      expect(assetTree.single.currencySymbol, '\$');
      expect(assetTree.single.children!.map((account) => account.id),
          [checkingId, savingsId]);
      expect(assetTree.single.children!.map((account) => account.amount),
          [100, 300]);

      final subTree = await repository.getAssetsAccountTree(
        ledgerId: ledgerId,
        parentId: assetsId,
      );
      expect(subTree.map((account) => account.id), [checkingId, savingsId]);

      final topAssetAccounts = await repository.getTopAssetAccountsByLedger(
        ledgerId: ledgerId,
        limit: 1,
      );
      expect(topAssetAccounts.single.account.accountId, savingsId);
      expect(topAssetAccounts.single.balance, 300);
    });

    test('liabilities repository top accounts use absolute balances by ledger',
        () async {
      final ledgerId = await _insertLedger(db, 'Main');
      final otherLedgerId = await _insertLedger(db, 'Other');

      final creditCardId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Credit Card',
        type: AccountType.LIABILITY,
      );
      final loanId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Loan',
        type: AccountType.LIABILITY,
      );
      final assetId = await _insertAccount(
        db,
        ledgerId: ledgerId,
        name: 'Cash',
        type: AccountType.ASSET,
      );
      final otherLedgerLiabilityId = await _insertAccount(
        db,
        ledgerId: otherLedgerId,
        name: 'Other Card',
        type: AccountType.LIABILITY,
      );

      final transactionId = await _insertTransaction(db, DateTime(2026, 5, 1));
      await _insertPosting(db, transactionId, creditCardId, -240);
      await _insertPosting(db, transactionId, loanId, -80);
      await _insertPosting(db, transactionId, assetId, 500);
      await _insertPosting(db, transactionId, otherLedgerLiabilityId, -1000);

      final repository =
          LiabilitiesRepository(db.accountDao, db.transactionDao);
      final topLiabilities = await repository.getTopLiabilityAccountsByLedger(
        ledgerId: ledgerId,
        limit: 2,
      );

      expect(topLiabilities.map((item) => item.account.accountId),
          [creditCardId, loanId]);
      expect(topLiabilities.map((item) => item.balance), [240, 80]);
    });
  });
}

Future<int> _insertLedger(AppDatabase db, String name) {
  return db.ledgerDao.insertLedger(LedgersCompanion.insert(name: name));
}

Future<int> _insertAccount(
  AppDatabase db, {
  required int ledgerId,
  required String name,
  required AccountType type,
  int? parentAccountId,
  bool isActive = true,
}) {
  return db.accountDao.insertAccount(
    AccountsCompanion.insert(
      ledgerId: ledgerId,
      parentAccountId: parentAccountId == null
          ? const Value.absent()
          : Value(parentAccountId),
      accountName: name,
      fullPath: name,
      accountType: type,
      isActive: Value(isActive),
    ),
  );
}

Future<int> _insertTransaction(AppDatabase db, DateTime date) {
  return db.transactionDao.insertTransaction(
    TransactionsCompanion.insert(transactionDate: date),
  );
}

Future<void> _insertPosting(
  AppDatabase db,
  int transactionId,
  int accountId,
  double amount,
) async {
  await db.postingDao.insertPosting(
    PostingsCompanion.insert(
      transactionId: transactionId,
      accountId: accountId,
      amount: amount,
    ),
  );
}
