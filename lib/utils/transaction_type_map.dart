import '../db/tables/account_table.dart';

// 交易类型枚举
enum TransactionType {
  CUSTOM('自定义'),
  EXPENSE('支出'),
  INCOME('收入'),
  ASSET_TRANSFER('资产转移'),
  DEBT_REPAYMENT('偿还债务'),
  LOAN_RECEIVED('获得贷款'),
  PERSONAL_INVESTMENT('个人投入'),
  PERSONAL_WITHDRAWAL('个人提取'),
  EXPENSE_REFUND('支出退款'),
  LOAN_EXPENSE('贷款支出');

  const TransactionType(this.displayName);
  final String displayName;

  static List<String> getAllDisplayNames() {
    return TransactionType.values.map((e) => e.displayName).toList();
  }
}

// Function to determine transaction flow type based on from and to account types.
// The returned strings are in Chinese.
String getTransactionFlowType(
    AccountType fromAccountType, AccountType toAccountType) {
  // Case 1: Asset -> Expense (e.g., paying rent from bank account)
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EXPENSE) {
    return TransactionType.EXPENSE.displayName;
  }
  // Case 2: Income -> Asset (e.g., salary credited to bank account)
  if (fromAccountType == AccountType.INCOME &&
      toAccountType == AccountType.ASSET) {
    return TransactionType.INCOME.displayName;
  }
  // Case 3: Liability -> Expense (e.g., an expense paid by increasing a liability, like using a credit card or a loan for an expense)
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.EXPENSE) {
    return TransactionType.LOAN_EXPENSE.displayName;
  }

  // Additional common transaction types
  // Asset transfers
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.ASSET) {
    return TransactionType
        .ASSET_TRANSFER.displayName; // e.g., moving cash from wallet to bank
  }

  // Debt related
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.LIABILITY) {
    return TransactionType.DEBT_REPAYMENT
        .displayName; // e.g., paying off a loan from bank account
  }
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.ASSET) {
    return TransactionType.LOAN_RECEIVED
        .displayName; // e.g., loan amount credited to bank account
  }

  // Equity related
  if (fromAccountType == AccountType.EQUITY &&
      toAccountType == AccountType.ASSET) {
    return TransactionType.PERSONAL_INVESTMENT
        .displayName; // e.g., owner invests capital into the business bank account
  }
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EQUITY) {
    return TransactionType.PERSONAL_WITHDRAWAL
        .displayName; // e.g., owner withdraws cash from the business
  }

  // Expense refund
  if (fromAccountType == AccountType.EXPENSE &&
      toAccountType == AccountType.ASSET) {
    return TransactionType.EXPENSE_REFUND
        .displayName; // e.g., a refunded expense credited to bank account
  }

  // Fallback for unhandled combinations
  return '其他类型'; // Other type
}

enum TransactionNature {
  INFLOW, // Represents an inflow of value
  OUTFLOW, // Represents an outflow of value
  TRANSFER, // Represents a transfer between similar types of accounts (e.g., asset to asset)
  OTHER, // Represents any other type of transaction not covered
}

TransactionNature getTransactionNature(
    AccountType? fromAccountType, AccountType? toAccountType) {
  if (fromAccountType == null || toAccountType == null) {
    return TransactionNature
        .OTHER; // Cannot determine nature if one of the account types is missing
  }

  // INFLOWS: Transactions that typically increase net worth or asset value from external sources/operations
  if (fromAccountType == AccountType.INCOME &&
      toAccountType == AccountType.ASSET) {
    return TransactionNature.INFLOW; // e.g., Salary (Income) to Bank (Asset)
  }
  if (fromAccountType == AccountType.EXPENSE &&
      toAccountType == AccountType.ASSET) {
    return TransactionNature
        .INFLOW; // e.g., Expense Refund (Expense reversal) to Bank (Asset)
  }
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.ASSET) {
    return TransactionNature
        .INFLOW; // e.g., Loan Received (Liability) in Bank (Asset)
  }
  if (fromAccountType == AccountType.EQUITY &&
      toAccountType == AccountType.ASSET) {
    return TransactionNature
        .INFLOW; // e.g., Capital Investment (Equity) into Bank (Asset)
  }

  // OUTFLOWS: Transactions that typically decrease net worth or asset value due to external obligations/operations
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EXPENSE) {
    return TransactionNature.OUTFLOW; // e.g., Bank (Asset) to Rent (Expense)
  }
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.EXPENSE) {
    // This case means an expense is paid by increasing a liability (e.g. using a credit card for an expense)
    // It's an outflow in terms of operational expense, even if an asset isn't directly reduced at this moment.
    return TransactionNature.OUTFLOW;
  }
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.LIABILITY) {
    return TransactionNature
        .OUTFLOW; // e.g., Bank (Asset) to Loan Repayment (Liability)
  }
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EQUITY) {
    return TransactionNature
        .OUTFLOW; // e.g., Cash Withdrawal (Asset) by Owner (Equity)
  }

  // TRANSFERS: Movement of value between accounts of the same fundamental type, usually neutral to net worth.
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.ASSET) {
    return TransactionNature.TRANSFER; // e.g., Wallet (Asset) to Bank (Asset)
  }
  // Consider if other same-type to same-type need to be transfers (e.g. Liability to Liability)

  // Default to OTHER if no specific rule matches
  return TransactionNature.OTHER;
}

double getBalanceChange({
  required bool isFromAccount,
  AccountType? fromAccountType,
  AccountType? toAccountType,
}) {
  if (isFromAccount) {
    if (fromAccountType == null) return 0;
    // Account is being used as source of funds
    switch (fromAccountType) {
      case AccountType.ASSET:
        return -1; // 资产减少
      case AccountType.LIABILITY:
        return -1; // 债务增加（负数变得更负，所以是-1）
      case AccountType.EQUITY:
        return -1; // 权益减少
      case AccountType.INCOME:
        return 1; // 收入增加
      case AccountType.EXPENSE:
        return -1; // 费用减少（退款场景）
    }
  } else {
    if (toAccountType == null) return 0;
    // Account is being used as destination of funds
    switch (toAccountType) {
      case AccountType.ASSET:
        return 1; // 资产增加
      case AccountType.LIABILITY:
        return 1; // 债务减少（负数变得不那么负，所以是+1）
      case AccountType.EQUITY:
        return 1; // 权益增加
      case AccountType.INCOME:
        return -1; // 收入冲减
      case AccountType.EXPENSE:
        return 1; // 费用增加
    }
  }
}
