import 'package:flowm/db/tables/account_table.dart' show AccountType;

class CreateTransactionCommand {
  const CreateTransactionCommand({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.fromAccountType,
    required this.toAccountType,
  });

  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final AccountType fromAccountType;
  final AccountType toAccountType;
}

class UpdateTransactionCommand {
  const UpdateTransactionCommand({
    required this.transactionId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.fromAccountType,
    required this.toAccountType,
  });

  final int transactionId;
  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final AccountType fromAccountType;
  final AccountType toAccountType;
}
