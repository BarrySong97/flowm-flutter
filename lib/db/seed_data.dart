import 'package:drift/drift.dart';
import 'dart:math'; // Added for Random
import 'app_database.dart';
import 'tables/account_table.dart';

/// This class provides seed data for initializing the double-entry accounting database
/// with common accounts and sample transactions suitable for the Chinese market.
class SeedData {
  final AppDatabase db;

  SeedData(this.db);

  /// Initialize the database with seed data
  Future<void> seedDatabase() async {
    final ledgerId = await _createDefaultLedger();
    await _createDefaultAccounts(ledgerId);
    await _createSampleTransactions(ledgerId);
    await _generateMonthlyTransactions(ledgerId);
    await _createDefaultTags();
  }

  /// Create default ledger
  Future<int> _createDefaultLedger() async {
    // 只创建个人账本
    final personalLedgerId = await db.ledgerDao.insertLedger(
      LedgersCompanion.insert(
        name: '示例账本',
        isSelected: const Value(true),
        description: const Value('个人日常收支记录'),
      ),
    );

    print('Created default ledger with ID: $personalLedgerId');
    return personalLedgerId;
  }

  /// Create default account hierarchy following Chinese accounting standards
  Future<void> _createDefaultAccounts(int ledgerId) async {
    // 使用账本ID创建账户
    final personalLedgerId = ledgerId;

    // Asset accounts
    final currentAssetsId = await _createAccount(
      personalLedgerId,
      null,
      '流动资产',
      '资产:流动资产',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      currentAssetsId,
      '现金',
      '资产:流动资产:现金',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      currentAssetsId,
      '银行存款',
      '资产:流动资产:银行存款',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      currentAssetsId,
      '支付宝',
      '资产:流动资产:支付宝',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      currentAssetsId,
      '微信支付',
      '资产:流动资产:微信支付',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      currentAssetsId,
      '应收账款',
      '资产:流动资产:应收账款',
      AccountType.ASSET,
    );

    // Fixed assets
    final fixedAssetsId = await _createAccount(
      personalLedgerId,
      null,
      '固定资产',
      '资产:固定资产',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      fixedAssetsId,
      '房产',
      '资产:固定资产:房产',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      fixedAssetsId,
      '车辆',
      '资产:固定资产:车辆',
      AccountType.ASSET,
    );

    await _createAccount(
      personalLedgerId,
      fixedAssetsId,
      '电子设备',
      '资产:固定资产:电子设备',
      AccountType.ASSET,
    );

    // Liability accounts
    final shortTermLiabilityId = await _createAccount(
      personalLedgerId,
      null,
      '流动负债',
      '负债:流动负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      shortTermLiabilityId,
      '信用卡',
      '负债:流动负债:信用卡',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      shortTermLiabilityId,
      '花呗',
      '负债:流动负债:花呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      shortTermLiabilityId,
      '白条',
      '负债:流动负债:白条',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      shortTermLiabilityId,
      '借呗',
      '负债:流动负债:借呗',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      shortTermLiabilityId,
      '应付账款',
      '负债:流动负债:应付账款',
      AccountType.LIABILITY,
    );

    final longTermLiabilityId = await _createAccount(
      personalLedgerId,
      null,
      '长期负债',
      '负债:长期负债',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      longTermLiabilityId,
      '房贷',
      '负债:长期负债:房贷',
      AccountType.LIABILITY,
    );

    await _createAccount(
      personalLedgerId,
      longTermLiabilityId,
      '车贷',
      '负债:长期负债:车贷',
      AccountType.LIABILITY,
    );

    // Equity accounts
    await _createAccount(
      personalLedgerId,
      null,
      '个人资本',
      '所有者权益:个人资本',
      AccountType.EQUITY,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '期初余额',
      '所有者权益:期初余额',
      AccountType.EQUITY,
    );

    // Income accounts
    await _createAccount(
      personalLedgerId,
      null,
      '工资收入',
      '收入:工资收入',
      AccountType.INCOME,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '奖金收入',
      '收入:奖金收入',
      AccountType.INCOME,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '投资收益',
      '收入:投资收益',
      AccountType.INCOME,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '理财收益',
      '收入:理财收益',
      AccountType.INCOME,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '兼职收入',
      '收入:兼职收入',
      AccountType.INCOME,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '其他收入',
      '收入:其他收入',
      AccountType.INCOME,
    );

    // Expense accounts
    final dailyExpensesId = await _createAccount(
      personalLedgerId,
      null,
      '日常支出',
      '支出:日常支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      dailyExpensesId,
      '餐饮',
      '支出:日常支出:餐饮',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      dailyExpensesId,
      '购物',
      '支出:日常支出:购物',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      dailyExpensesId,
      '交通',
      '支出:日常支出:交通',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      dailyExpensesId,
      '娱乐',
      '支出:日常支出:娱乐',
      AccountType.EXPENSE,
    );

    final housingExpensesId = await _createAccount(
      personalLedgerId,
      null,
      '住房支出',
      '支出:住房支出',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      housingExpensesId,
      '房租',
      '支出:住房支出:房租',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      housingExpensesId,
      '物业费',
      '支出:住房支出:物业费',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      housingExpensesId,
      '水电煤',
      '支出:住房支出:水电煤',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '通讯',
      '支出:通讯',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '医疗',
      '支出:医疗',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '教育',
      '支出:教育',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '保险',
      '支出:保险',
      AccountType.EXPENSE,
    );

    await _createAccount(
      personalLedgerId,
      null,
      '税费',
      '支出:税费',
      AccountType.EXPENSE,
    );
  }

  /// Create sample transactions with postings that balance (debits = credits)
  Future<void> _createSampleTransactions(int ledgerId) async {
    // Get account IDs for sample transactions
    final accounts = await db.accountDao.getAccountsByLedgerId(ledgerId);

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

  /// 生成带随机时间的日期时间
  DateTime _generateRandomDateTime(Random random, DateTime date, {bool isWorkingHours = false}) {
    int randomHour, randomMinute;
    
    if (isWorkingHours) {
      // 工作时间段 9:00-18:00
      randomHour = random.nextInt(10) + 9;
    } else {
      // 全天时间段 7:00-23:00
      randomHour = random.nextInt(17) + 7;
    }
    
    randomMinute = random.nextInt(60);
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      randomHour,
      randomMinute,
    );
  }

  /// Generates a large number of transactions for the previous month.
  Future<void> _generateMonthlyTransactions(int ledgerId) async {
    final random = Random();
    final now = DateTime.now();
    // Generate data for the past month, starting from today and going back one month.
    final endOfPeriod = DateTime(now.year, now.month, now.day);
    final startOfPeriod = DateTime(now.year, now.month - 1, now.day);

    final allAccounts = await db.accountDao.getAccountsByLedgerId(ledgerId);

    // Helper to find account by full path
    Account? findAccount(String path) {
      try {
        return allAccounts.firstWhere((a) => a.fullPath == path);
      } catch (e) {
        print(
            'Account with path "$path" not found. It might not have been created yet or the path is incorrect.');
        return null;
      }
    }

    // Define asset, expense, income and liability accounts to be used
    final assetAccounts = [
      findAccount('资产:流动资产:现金'),
      findAccount('资产:流动资产:银行存款'),
      findAccount('资产:流动资产:支付宝'),
      findAccount('资产:流动资产:微信支付'),
    ].where((a) => a != null).cast<Account>().toList();

    final expenseAccounts = [
      findAccount('支出:日常支出:餐饮'),
      findAccount('支出:日常支出:购物'),
      findAccount('支出:日常支出:交通'),
      findAccount('支出:日常支出:娱乐'),
      findAccount('支出:住房支出:水电煤'),
      findAccount('支出:通讯'),
      findAccount('支出:医疗'),
      findAccount('支出:教育'),
    ].where((a) => a != null).cast<Account>().toList();

    final incomeAccounts = [
      findAccount('收入:工资收入'),
      findAccount('收入:奖金收入'),
      findAccount('收入:兼职收入'),
      findAccount('收入:理财收益'),
    ].where((a) => a != null).cast<Account>().toList();

    final liabilityAccounts = [
      findAccount('负债:流动负债:信用卡'),
      findAccount('负债:流动负债:花呗'),
      findAccount('负债:流动负债:白条'),
      findAccount('负债:流动负债:借呗'),
      findAccount('负债:长期负债:房贷'),
      findAccount('负债:长期负债:车贷'),
    ].where((a) => a != null).cast<Account>().toList();

    if (assetAccounts.isEmpty ||
        expenseAccounts.isEmpty ||
        incomeAccounts.isEmpty ||
        liabilityAccounts.isEmpty) {
      print(
          'Warning: Not enough asset, expense, income, or liability accounts found for generating yearly transactions. Skipping generation.');
      return;
    }

    final creditCardAccount = findAccount('负债:流动负债:信用卡');
    final huabeiAccount = findAccount('负债:流动负债:花呗');
    final baitiaoAccount = findAccount('负债:流动负债:白条');
    final mortgageAccount = findAccount('负债:长期负债:房贷');
    final carLoanAccount = findAccount('负债:长期负债:车贷');
    final bankAccount = findAccount('资产:流动资产:银行存款');

    final List<String> commonExpenseDescriptions = [
      '午餐',
      '晚餐',
      '早餐',
      '买咖啡',
      '买奶茶',
      '超市购物',
      '买菜',
      '水果零食',
      '地铁',
      '公交',
      '打车',
      '共享单车',
      '电影票',
      '聚餐 KTV',
      '饮料',
      '话费充值',
      '水电煤缴费',
      '淘宝购物',
      '京东购物',
      '拼多多购物',
      '美团外卖',
      '饿了么外卖',
      '日常用品',
      '服装鞋包',
      '美容美发',
      '健身运动',
      '宠物用品',
      '医疗挂号',
      '买药',
      '书籍学习',
      '培训课程',
      '考试报名费',
      '孩子教育',
      '交通罚款',
      '红包支出',
      '请客吃饭'
    ];

    final List<String> incomeDescriptions = [
      '工资',
      '奖金',
      '项目提成',
      '稿费收入',
      '兼职收入',
      '理财收益',
      '股票收益',
      '基金收益',
      '二手物品出售',
      '红包收入'
    ];

    for (var day = 0;
        day <= endOfPeriod.difference(startOfPeriod).inDays;
        day++) {
      final currentDate = startOfPeriod.add(Duration(days: day));

      // Simulate monthly salary on the 5th or 10th
      if ((currentDate.day == 5 || currentDate.day == 10) &&
          incomeAccounts.isNotEmpty &&
          bankAccount != null) {
        final salarySourceAccount =
            incomeAccounts[random.nextInt(incomeAccounts.length)];
        final salaryAmount =
            (random.nextDouble() * 8000 + 7000).roundToDouble(); // 7000-15000
        String description =
            incomeDescriptions[random.nextInt(incomeDescriptions.length)];
        if (description == '工资' || description == '奖金') {
          description = '${currentDate.month}月$description';
        }

        final salaryTransactionId = await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            transactionDate: _generateRandomDateTime(random, currentDate, isWorkingHours: true),
            description: Value(description),
          ),
        );
        await db.postingDao.insertPostings([
          PostingsCompanion.insert(
            transactionId: salaryTransactionId,
            accountId: bankAccount.accountId,
            amount: salaryAmount,
          ),
          PostingsCompanion.insert(
            transactionId: salaryTransactionId,
            accountId: salarySourceAccount.accountId,
            amount: -salaryAmount,
          ),
        ]);
      }

      // Simulate monthly mortgage payment on the 15th
      if (currentDate.day == 15 &&
          mortgageAccount != null &&
          bankAccount != null) {
        final mortgagePaymentAmount =
            (random.nextDouble() * 3000 + 4000).roundToDouble(); // 4000-7000
        final transactionId = await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            transactionDate: _generateRandomDateTime(random, currentDate),
            description: Value('${currentDate.month}月房贷还款'),
          ),
        );
        await db.postingDao.insertPostings([
          PostingsCompanion.insert(
            transactionId: transactionId,
            accountId: mortgageAccount.accountId,
            amount: mortgagePaymentAmount, // Debit liability (decrease)
          ),
          PostingsCompanion.insert(
            transactionId: transactionId,
            accountId: bankAccount.accountId,
            amount: -mortgagePaymentAmount, // Credit asset (decrease)
          ),
        ]);
      }

      // Simulate monthly car loan payment on the 20th
      if (currentDate.day == 20 &&
          carLoanAccount != null &&
          bankAccount != null) {
        final carLoanPaymentAmount =
            (random.nextDouble() * 1000 + 1500).roundToDouble(); // 1500-2500
        final transactionId = await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            transactionDate: _generateRandomDateTime(random, currentDate),
            description: Value('${currentDate.month}月车贷还款'),
          ),
        );
        await db.postingDao.insertPostings([
          PostingsCompanion.insert(
            transactionId: transactionId,
            accountId: carLoanAccount.accountId,
            amount: carLoanPaymentAmount, // Debit liability (decrease)
          ),
          PostingsCompanion.insert(
            transactionId: transactionId,
            accountId: bankAccount.accountId,
            amount: -carLoanPaymentAmount, // Credit asset (decrease)
          ),
        ]);
      }

      // Simulate credit card, Huabei, Baitiao repayments (e.g., on 1st, 10th, 25th)
      if ((currentDate.day == 1 ||
              currentDate.day == 10 ||
              currentDate.day == 25) &&
          bankAccount != null) {
        if (creditCardAccount != null && random.nextBool()) {
          // Repay Credit Card
          final amount =
              (random.nextDouble() * 2000 + 500).roundToDouble(); // 500 - 2500
          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value('信用卡还款'),
            ),
          );
          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: creditCardAccount.accountId,
              amount: amount,
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: bankAccount.accountId,
              amount: -amount,
            ),
          ]);
        }
        if (huabeiAccount != null && random.nextBool()) {
          // Repay Huabei
          final amount =
              (random.nextDouble() * 1000 + 200).roundToDouble(); // 200 - 1200
          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value('花呗还款'),
            ),
          );
          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: huabeiAccount.accountId,
              amount: amount,
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: bankAccount.accountId, // Assume paid from bank
              amount: -amount,
            ),
          ]);
        }
        if (baitiaoAccount != null && random.nextBool()) {
          // Repay Baitiao
          final amount =
              (random.nextDouble() * 800 + 100).roundToDouble(); // 100 - 900
          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value('白条还款'),
            ),
          );
          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: baitiaoAccount.accountId,
              amount: amount,
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: bankAccount.accountId, // Assume paid from bank
              amount: -amount,
            ),
          ]);
        }
      }

      // Random number of other transactions for the day (1-5)
      final numTransactionsToday = random.nextInt(5) + 1;

      for (var i = 0; i < numTransactionsToday; i++) {
        final transactionType =
            random.nextDouble(); // Use double for more granular probability

        if (transactionType < 0.75) {
          // 75% chance of expense
          if (expenseAccounts.isEmpty || assetAccounts.isEmpty) continue;

          final expenseAccount =
              expenseAccounts[random.nextInt(expenseAccounts.length)];
          // Prioritize non-cash payments, more realistic
          Account paymentAccount;
          final paymentMethodRoll = random.nextDouble();
          if (paymentMethodRoll < 0.4 && huabeiAccount != null) {
            // 40% Huabei
            paymentAccount = huabeiAccount;
          } else if (paymentMethodRoll < 0.7 && baitiaoAccount != null) {
            // 30% Baitiao
            paymentAccount = baitiaoAccount;
          } else if (paymentMethodRoll < 0.9 && creditCardAccount != null) {
            // 20% Credit Card
            paymentAccount = creditCardAccount;
          } else {
            // 10% other asset accounts (Alipay, WeChat, Bank, Cash)
            paymentAccount =
                assetAccounts[random.nextInt(assetAccounts.length)];
          }

          // More realistic amounts based on expense type
          double amountValue;
          if (expenseAccount.accountName.contains('餐饮') ||
              expenseAccount.accountName.contains('交通')) {
            amountValue =
                (random.nextDouble() * 100 + 10).roundToDouble(); // 10-110
          } else if (expenseAccount.accountName.contains('购物') ||
              expenseAccount.accountName.contains('娱乐')) {
            amountValue =
                (random.nextDouble() * 400 + 50).roundToDouble(); // 50-450
          } else if (expenseAccount.accountName.contains('医疗') ||
              expenseAccount.accountName.contains('教育')) {
            amountValue =
                (random.nextDouble() * 1000 + 100).roundToDouble(); // 100-1100
          } else {
            amountValue = (random.nextDouble() * 200 + 20)
                .roundToDouble(); // 20-220 for others
          }
          final amount = amountValue.toStringAsFixed(2);

          final description = commonExpenseDescriptions[
              random.nextInt(commonExpenseDescriptions.length)];

          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value(description),
            ),
          );

          // If payment is from Huabei/Baitiao/CreditCard, the posting to liability account is negative (increase liability)
          // If payment is from an asset account, the posting is negative (decrease asset)
          final paymentAmount =
              paymentAccount.accountType == AccountType.LIABILITY
                  ? -double.parse(amount)
                  : -double.parse(amount);

          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: expenseAccount.accountId,
              amount: double.parse(amount), // Debit Expense
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: paymentAccount.accountId,
              amount: paymentAmount, // Credit Asset or Liability
            ),
          ]);
        } else if (transactionType < 0.9) {
          // 15% chance of income (less frequent than expenses)
          if (incomeAccounts.isEmpty || assetAccounts.isEmpty) continue;
          final incomeSourceAccount =
              incomeAccounts[random.nextInt(incomeAccounts.length)];
          final depositAccount = assetAccounts[random
              .nextInt(assetAccounts.length)]; // Income to any asset account
          final amount = (random.nextDouble() * 1000 + 100)
              .toStringAsFixed(2); // 100 - 1100
          final description =
              incomeDescriptions[random.nextInt(incomeDescriptions.length)];
          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value(description),
            ),
          );
          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: depositAccount.accountId,
              amount: double.parse(amount),
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: incomeSourceAccount.accountId,
              amount: -double.parse(amount),
            ),
          ]);
        } else {
          // 10% chance of transfer
          if (assetAccounts.length < 2) continue;

          final fromAccount =
              assetAccounts[random.nextInt(assetAccounts.length)];
          Account toAccount;
          do {
            toAccount = assetAccounts[random.nextInt(assetAccounts.length)];
          } while (toAccount.accountId == fromAccount.accountId);

          final amount =
              (random.nextDouble() * 2000 + 100).toStringAsFixed(2); // 100-2100
          final description =
              '转账从 ${fromAccount.accountName} 到 ${toAccount.accountName}';

          final transactionId = await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              transactionDate: _generateRandomDateTime(random, currentDate),
              description: Value(description),
            ),
          );
          await db.postingDao.insertPostings([
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: toAccount.accountId,
              amount: double.parse(amount),
            ),
            PostingsCompanion.insert(
              transactionId: transactionId,
              accountId: fromAccount.accountId,
              amount: -double.parse(amount),
            ),
          ]);
        }
      }
    }
    print('Finished generating monthly transactions for the past month.');
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
    int ledgerId,
    int? parentId,
    String name,
    String fullPath,
    AccountType type,
  ) async {
    return await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        ledgerId: ledgerId,
        parentAccountId:
            parentId != null ? Value(parentId) : const Value.absent(),
        accountName: name,
        fullPath: fullPath,
        accountType: type,
      ),
    );
  }
}
