import '../db/dao/transaction_dao.dart'; // For TransactionWithAmount
import 'transaction_type_map.dart'; // For TransactionNature

/// Calculates the total income and expenses from a list of daily transactions.
///
/// [dailyTransactions] - A list of [TransactionWithAmount] for a specific day.
/// Returns a map with keys 'income' and 'expenses'.
Map<String, double> calculateDailyIncomeAndExpense(
    List<TransactionWithAmount> dailyTransactions) {
  double income = 0.0;
  double expense = 0.0;

  for (final transactionWithAmount in dailyTransactions) {
    if (transactionWithAmount.nature == TransactionNature.INFLOW) {
      income += transactionWithAmount.amount.abs();
    } else if (transactionWithAmount.nature == TransactionNature.OUTFLOW) {
      expense += transactionWithAmount.amount.abs();
    }
    // Transactions with nature TRANSFER or OTHER are not typically counted
    // towards income/expense totals.
  }
  return {'income': income, 'expenses': expense};
}
