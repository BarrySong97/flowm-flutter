import '../db/tables/account_table.dart';

// Function to determine transaction flow type based on from and to account types.
// The returned strings are in Chinese.
String getTransactionFlowType(
    AccountType fromAccountType, AccountType toAccountType) {
  // Case 1: Asset -> Expense (e.g., paying rent from bank account)
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EXPENSE) {
    return '支出';
  }
  // Case 2: Income -> Asset (e.g., salary credited to bank account)
  if (fromAccountType == AccountType.INCOME &&
      toAccountType == AccountType.ASSET) {
    return '收入';
  }
  // Case 3: Liability -> Expense (e.g., an expense paid by increasing a liability, like using a credit card or a loan for an expense)
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.EXPENSE) {
    return '贷款支出';
  }

  // Additional common transaction types
  // Asset transfers
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.ASSET) {
    return '资产转移'; // e.g., moving cash from wallet to bank
  }

  // Debt related
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.LIABILITY) {
    return '偿还债务'; // e.g., paying off a loan from bank account
  }
  if (fromAccountType == AccountType.LIABILITY &&
      toAccountType == AccountType.ASSET) {
    return '获得贷款'; // e.g., loan amount credited to bank account
  }

  // Equity related
  if (fromAccountType == AccountType.EQUITY &&
      toAccountType == AccountType.ASSET) {
    return '股东投入'; // e.g., owner invests capital into the business bank account
  }
  if (fromAccountType == AccountType.ASSET &&
      toAccountType == AccountType.EQUITY) {
    return '股东提取'; // e.g., owner withdraws cash from the business
  }

  // Expense refund
  if (fromAccountType == AccountType.EXPENSE &&
      toAccountType == AccountType.ASSET) {
    return '费用退款'; // e.g., a refunded expense credited to bank account
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
