import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables/account_table.dart';

/// This class provides seed data for initializing the double-entry accounting database
/// with common accounts and sample transactions suitable for the Chinese market.
class SeedData {
  final AppDatabase db;

  SeedData(this.db);

  /// Initialize the database with seed data
  Future<void> seedDatabase() async {
    await _createDefaultAccounts();
    await _createSampleTransactions();
    await _createDefaultTags();
  }

  /// Create default account hierarchy following Chinese accounting standards
  Future<void> _createDefaultAccounts() async {
    // Root accounts (main categories)
    final assetId = await _createAccount(
      null,
      '资产',
      '资产',
      AccountType.ASSET,
    );

    final liabilityId = await _createAccount(
      null,
      '负债',
      '负债',
      AccountType.LIABILITY,
    );

    final equityId = await _createAccount(
      null,
      '所有者权益',
      '所有者权益',
      AccountType.EQUITY,
    );

    final incomeId = await _createAccount(
      null,
      '收入',
      '收入',
      AccountType.INCOME,
    );

    final expenseId = await _createAccount(
      null,
      '支出',
      '支出',
      AccountType.EXPENSE,
    );

    // Asset accounts
    final currentAssetsId = await _createAccount(
      assetId,
      '流动资产',
      '资产:流动资产',
      AccountType.ASSET,
    );

    await _createAccount(
      currentAssetsId,
      '现金',
      '资产:流动资产:现金',
      AccountType.ASSET,
    );

    await _createAccount(
      currentAssetsId,
      '银行存款',
      '资产:流动资产:银行存款',
      AccountType.ASSET,
    );

    await _createAccount(
      currentAssetsId,
      '支付宝',
      '资产:流动资产:支付宝',
      AccountType.ASSET,
    );

    await _createAccount(
      currentAssetsId,
      '微信支付',
      '资产:流动资产:微信支付',
      AccountType.ASSET,
    );

    await _createAccount(
      currentAssetsId,
      '应收账款',
      '资产:流动资产:应收账款',
      AccountType.ASSET,
    );

    // Fixed assets
    final fixedAssetsId = await _createAccount(
      assetId,
      '固定资产',
      '资产:固定资产',
      AccountType.ASSET,
    );

    await _createAccount(
      fixedAssetsId,
      '房产',
      '资产:固定资产:房产',
      AccountType.ASSET,
    );

    await _createAccount(
      fixedAssetsId,
      '车辆',
      '资产:固定资产:车辆',
      AccountType.ASSET,
    );

    await _createAccount(
      fixedAssetsId,
      '电子设备',
      '资产:固定资产:电子设备',
      AccountType.ASSET,
    );

    // Liability accounts
    final shortTermLiabilityId = await _createAccount(
      liabilityId,
      '流动负债',
      '负债:流动负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      shortTermLiabilityId,
      '信用卡',
      '负债:流动负债:信用卡',
      AccountType.LIABILITY,
    );

    await _createAccount(
      shortTermLiabilityId,
      '花呗',
      '负债:流动负债:花呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      shortTermLiabilityId,
      '借呗',
      '负债:流动负债:借呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      shortTermLiabilityId,
      '应付账款',
      '负债:流动负债:应付账款',
      AccountType.LIABILITY,
    );

    final longTermLiabilityId = await _createAccount(
      liabilityId,
      '长期负债',
      '负债:长期负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      longTermLiabilityId,
      '房贷',
      '负债:长期负债:房贷',
      AccountType.LIABILITY,
    );

    await _createAccount(
      longTermLiabilityId,
      '车贷',
      '负债:长期负债:车贷',
      AccountType.LIABILITY,
    );

    // Equity accounts
    await _createAccount(
      equityId,
      '个人资本',
      '所有者权益:个人资本',
      AccountType.EQUITY,
    );

    await _createAccount(
      equityId,
      '期初余额',
      '所有者权益:期初余额',
      AccountType.EQUITY,
    );

    // Income accounts
    await _createAccount(
      incomeId,
      '工资收入',
      '收入:工资收入',
      AccountType.INCOME,
    );

    await _createAccount(
      incomeId,
      '奖金收入',
      '收入:奖金收入',
      AccountType.INCOME,
    );

    await _createAccount(
      incomeId,
      '投资收益',
      '收入:投资收益',
      AccountType.INCOME,
    );

    await _createAccount(
      incomeId,
      '理财收益',
      '收入:理财收益',
      AccountType.INCOME,
    );

    await _createAccount(
      incomeId,
      '兼职收入',
      '收入:兼职收入',
      AccountType.INCOME,
    );

    await _createAccount(
      incomeId,
      '其他收入',
      '收入:其他收入',
      AccountType.INCOME,
    );

    // Expense accounts
    final dailyExpensesId = await _createAccount(
      expenseId,
      '日常支出',
      '支出:日常支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      dailyExpensesId,
      '餐饮',
      '支出:日常支出:餐饮',
      AccountType.EXPENSE,
    );

    await _createAccount(
      dailyExpensesId,
      '购物',
      '支出:日常支出:购物',
      AccountType.EXPENSE,
    );

    await _createAccount(
      dailyExpensesId,
      '交通',
      '支出:日常支出:交通',
      AccountType.EXPENSE,
    );

    await _createAccount(
      dailyExpensesId,
      '娱乐',
      '支出:日常支出:娱乐',
      AccountType.EXPENSE,
    );

    final housingExpensesId = await _createAccount(
      expenseId,
      '住房支出',
      '支出:住房支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      housingExpensesId,
      '房租',
      '支出:住房支出:房租',
      AccountType.EXPENSE,
    );

    await _createAccount(
      housingExpensesId,
      '物业费',
      '支出:住房支出:物业费',
      AccountType.EXPENSE,
    );

    await _createAccount(
      housingExpensesId,
      '水电煤',
      '支出:住房支出:水电煤',
      AccountType.EXPENSE,
    );

    await _createAccount(
      expenseId,
      '通讯',
      '支出:通讯',
      AccountType.EXPENSE,
    );

    await _createAccount(
      expenseId,
      '医疗',
      '支出:医疗',
      AccountType.EXPENSE,
    );

    await _createAccount(
      expenseId,
      '教育',
      '支出:教育',
      AccountType.EXPENSE,
    );

    await _createAccount(
      expenseId,
      '保险',
      '支出:保险',
      AccountType.EXPENSE,
    );

    await _createAccount(
      expenseId,
      '税费',
      '支出:税费',
      AccountType.EXPENSE,
    );
  }

  /// Create sample transactions with postings that balance (debits = credits)
  Future<void> _createSampleTransactions() async {
    // Get account IDs for sample transactions
    final accounts = await db.accountDao.getAllAccounts();

    // Find accounts by their full paths
    final bankAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:流动资产:银行存款');
    final wechatAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:流动资产:微信支付');
    final alipayAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:流动资产:支付宝');
    final cashAccount = accounts.firstWhere((a) => a.fullPath == '资产:流动资产:现金');
    final accountsReceivableAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:流动资产:应收账款');
    final propertyAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:固定资产:房产');
    final vehicleAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:固定资产:车辆');
    final electronicsAccount =
        accounts.firstWhere((a) => a.fullPath == '资产:固定资产:电子设备');
    final salaryIncomeAccount =
        accounts.firstWhere((a) => a.fullPath == '收入:工资收入');
    final restaurantExpAccount =
        accounts.firstWhere((a) => a.fullPath == '支出:日常支出:餐饮');
    final transportExpAccount =
        accounts.firstWhere((a) => a.fullPath == '支出:日常支出:交通');
    final shoppingExpAccount =
        accounts.firstWhere((a) => a.fullPath == '支出:日常支出:购物');
    final openingBalanceAccount =
        accounts.firstWhere((a) => a.fullPath == '所有者权益:期初余额');
    final creditCardAccount =
        accounts.firstWhere((a) => a.fullPath == '负债:流动负债:信用卡');
    final utilityExpAccount =
        accounts.firstWhere((a) => a.fullPath == '支出:住房支出:水电煤');
    final mortgageAccount =
        accounts.firstWhere((a) => a.fullPath == '负债:长期负债:房贷');
    final carLoanAccount =
        accounts.firstWhere((a) => a.fullPath == '负债:长期负债:车贷');
    final personalCapitalAccount =
        accounts.firstWhere((a) => a.fullPath == '所有者权益:个人资本');

    // Transaction 1: Initial balance
    final initialBalanceId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 1, 1),
        description: const Value('期初余额'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: bankAccount.accountId,
        amount: 10000.0, // 10,000 元初始银行存款
      ),
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: alipayAccount.accountId,
        amount: 2000.0, // 2,000 元初始支付宝余额
      ),
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: wechatAccount.accountId,
        amount: 1500.0, // 1,500 元初始微信余额
      ),
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: cashAccount.accountId,
        amount: 2000.0, // 2,000 元现金
      ),
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: creditCardAccount.accountId,
        amount: -3000.0, // -3,000 元初始信用卡欠款
      ),
      PostingsCompanion.insert(
        transactionId: initialBalanceId,
        accountId: openingBalanceAccount.accountId,
        amount: -12500.0, // -12,500 元，平衡以上款项
      ),
    ]);

    // Transaction: Initial property (house) valuation
    final propertyValuationId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 1, 1),
        description: const Value('房产初始估值'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: propertyValuationId,
        accountId: propertyAccount.accountId,
        amount: 2000000.0, // 200万元房产估值
      ),
      PostingsCompanion.insert(
        transactionId: propertyValuationId,
        accountId: mortgageAccount.accountId,
        amount: -1200000.0, // -120万元未还房贷
      ),
      PostingsCompanion.insert(
        transactionId: propertyValuationId,
        accountId: personalCapitalAccount.accountId,
        amount: -800000.0, // -80万元个人资本（房产净值）
      ),
    ]);

    // Transaction: Initial vehicle valuation
    final vehicleValuationId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 1, 1),
        description: const Value('车辆初始估值'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: vehicleValuationId,
        accountId: vehicleAccount.accountId,
        amount: 180000.0, // 18万元车辆估值
      ),
      PostingsCompanion.insert(
        transactionId: vehicleValuationId,
        accountId: carLoanAccount.accountId,
        amount: -80000.0, // -8万元未还车贷
      ),
      PostingsCompanion.insert(
        transactionId: vehicleValuationId,
        accountId: personalCapitalAccount.accountId,
        amount: -100000.0, // -10万元个人资本（车辆净值）
      ),
    ]);

    // Transaction: Electronic devices valuation
    final electronicsValuationId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 1, 1),
        description: const Value('电子设备初始估值'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: electronicsValuationId,
        accountId: electronicsAccount.accountId,
        amount: 25000.0, // 2.5万元电子设备估值（电脑、手机等）
      ),
      PostingsCompanion.insert(
        transactionId: electronicsValuationId,
        accountId: personalCapitalAccount.accountId,
        amount: -25000.0, // -2.5万元个人资本
      ),
    ]);

    // Transaction: Accounts receivable
    final accountsReceivableId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 1, 15),
        description: const Value('应收账款初始化'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: accountsReceivableId,
        accountId: accountsReceivableAccount.accountId,
        amount: 5000.0, // 5,000元应收账款
      ),
      PostingsCompanion.insert(
        transactionId: accountsReceivableId,
        accountId: personalCapitalAccount.accountId,
        amount: -5000.0, // -5,000元个人资本
      ),
    ]);

    // Transaction 2: Salary income
    final salaryTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 5),
        description: const Value('2月工资收入'),
        isRecurring: const Value(true),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: salaryTransId,
        accountId: bankAccount.accountId,
        amount: 12000.0, // 12,000 元工资收入
      ),
      PostingsCompanion.insert(
        transactionId: salaryTransId,
        accountId: salaryIncomeAccount.accountId,
        amount: -12000.0, // -12,000 元（贷方）收入科目
      ),
    ]);

    // Transaction 3: Restaurant expense
    final restaurantTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 10),
        description: const Value('海底捞火锅消费'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: restaurantTransId,
        accountId: restaurantExpAccount.accountId,
        amount: 368.50, // 368.50 元餐饮支出
      ),
      PostingsCompanion.insert(
        transactionId: restaurantTransId,
        accountId: wechatAccount.accountId,
        amount: -368.50, // -368.50 元从微信支付
      ),
    ]);

    // Transaction 4: Grocery shopping
    final shoppingTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 12),
        description: const Value('盒马鲜生超市购物'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: shoppingTransId,
        accountId: shoppingExpAccount.accountId,
        amount: 253.75, // 253.75 元购物支出
      ),
      PostingsCompanion.insert(
        transactionId: shoppingTransId,
        accountId: alipayAccount.accountId,
        amount: -253.75, // -253.75 元从支付宝支付
      ),
    ]);

    // Transaction 5: Utilities payment
    final utilityTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 15),
        description: const Value('水电费'),
        isRecurring: const Value(true),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: utilityTransId,
        accountId: utilityExpAccount.accountId,
        amount: 245.0, // 245.00 元水电费
      ),
      PostingsCompanion.insert(
        transactionId: utilityTransId,
        accountId: bankAccount.accountId,
        amount: -245.0, // -245.00 元从银行账户支付
      ),
    ]);

    // Transaction 6: Transport (DiDi)
    final transportTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 18),
        description: const Value('滴滴打车'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: transportTransId,
        accountId: transportExpAccount.accountId,
        amount: 45.50, // 45.50 元交通费
      ),
      PostingsCompanion.insert(
        transactionId: transportTransId,
        accountId: alipayAccount.accountId,
        amount: -45.50, // -45.50 元从支付宝支付
      ),
    ]);

    // Transaction 7: Credit card payment
    final ccPaymentTransId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 20),
        description: const Value('信用卡还款'),
        isRecurring: const Value(true),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: ccPaymentTransId,
        accountId: creditCardAccount.accountId,
        amount: 3000.0, // 3,000 元信用卡还款
      ),
      PostingsCompanion.insert(
        transactionId: ccPaymentTransId,
        accountId: bankAccount.accountId,
        amount: -3000.0, // -3,000 元从银行账户支付
      ),
    ]);

    // Transaction 8: Mortgage payment
    final mortgagePaymentId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 25),
        description: const Value('房贷还款'),
        isRecurring: const Value(true),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: mortgagePaymentId,
        accountId: mortgageAccount.accountId,
        amount: 6000.0, // 6,000 元房贷还款
      ),
      PostingsCompanion.insert(
        transactionId: mortgagePaymentId,
        accountId: bankAccount.accountId,
        amount: -6000.0, // -6,000 元从银行账户支付
      ),
    ]);

    // Transaction 9: Car loan payment
    final carLoanPaymentId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 25),
        description: const Value('车贷还款'),
        isRecurring: const Value(true),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: carLoanPaymentId,
        accountId: carLoanAccount.accountId,
        amount: 2000.0, // 2,000 元车贷还款
      ),
      PostingsCompanion.insert(
        transactionId: carLoanPaymentId,
        accountId: bankAccount.accountId,
        amount: -2000.0, // -2,000 元从银行账户支付
      ),
    ]);

    // Transaction 10: Collecting accounts receivable
    final collectReceivableId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 2, 27),
        description: const Value('收回应收账款'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: collectReceivableId,
        accountId: bankAccount.accountId,
        amount: 3000.0, // 3,000 元收回部分应收账款
      ),
      PostingsCompanion.insert(
        transactionId: collectReceivableId,
        accountId: accountsReceivableAccount.accountId,
        amount: -3000.0, // -3,000 元从应收账款减少
      ),
    ]);

    // Transaction 11: New electronic device purchase
    final electronicsPurchaseId = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        transactionDate: DateTime(2023, 3, 15),
        description: const Value('购买新手机'),
        isRecurring: const Value(false),
      ),
    );

    await db.postingDao.insertPostings([
      PostingsCompanion.insert(
        transactionId: electronicsPurchaseId,
        accountId: electronicsAccount.accountId,
        amount: 8000.0, // 8,000 元新手机价值
      ),
      PostingsCompanion.insert(
        transactionId: electronicsPurchaseId,
        accountId: alipayAccount.accountId,
        amount: -8000.0, // -8,000 元从支付宝支付
      ),
    ]);
  }

  /// Create default tags for transaction categorization
  Future<void> _createDefaultTags() async {
    await db.tagDao.insertTag(
      TagsCompanion.insert(
        tagName: '必要开销',
        displayColor: const Value('#FF5722'),
      ),
    );

    await db.tagDao.insertTag(
      TagsCompanion.insert(
        tagName: '非必要开销',
        displayColor: const Value('#9C27B0'),
      ),
    );

    await db.tagDao.insertTag(
      TagsCompanion.insert(
        tagName: '投资',
        displayColor: const Value('#4CAF50'),
      ),
    );

    await db.tagDao.insertTag(
      TagsCompanion.insert(
        tagName: '日常生活',
        displayColor: const Value('#2196F3'),
      ),
    );

    await db.tagDao.insertTag(
      TagsCompanion.insert(
        tagName: '娱乐',
        displayColor: const Value('#FFC107'),
      ),
    );
  }

  /// Helper method to create accounts
  Future<int> _createAccount(
    int? parentId,
    String name,
    String fullPath,
    AccountType type,
  ) async {
    return await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        parentAccountId:
            parentId != null ? Value(parentId) : const Value.absent(),
        accountName: name,
        fullPath: fullPath,
        accountType: type,
      ),
    );
  }
}
