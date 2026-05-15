import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/db/tables/account_table.dart' show AccountType;
import 'package:flowm/features/transactions/domain/transaction_command.dart';
import 'package:flowm/state/transaction/transaction_repository.dart';
import 'package:flowm/utils/provider_invalidator.dart';

final transactionCommandControllerProvider =
    Provider<TransactionCommandController>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return TransactionCommandController(ref, transactionRepository);
});

class TransactionCommandController {
  const TransactionCommandController(this._ref, this._transactionRepository);

  final Ref _ref;
  final TransactionRepository _transactionRepository;

  Future<void> create(CreateTransactionCommand command) async {
    await _transactionRepository.createTransactionWithPostings(
      fromAccountId: command.fromAccountId,
      toAccountId: command.toAccountId,
      amount: command.amount,
      transactionDate: command.transactionDate,
      description: command.description,
    );

    _invalidateChangedProviders(
      fromAccountType: command.fromAccountType,
      toAccountType: command.toAccountType,
    );
  }

  Future<void> update(UpdateTransactionCommand command) async {
    await _transactionRepository.updateTransactionWithPostings(
      transactionId: command.transactionId,
      fromAccountId: command.fromAccountId,
      toAccountId: command.toAccountId,
      amount: command.amount,
      transactionDate: command.transactionDate,
      description: command.description,
    );

    _invalidateChangedProviders(
      fromAccountType: command.fromAccountType,
      toAccountType: command.toAccountType,
    );
  }

  void _invalidateChangedProviders({
    required AccountType fromAccountType,
    required AccountType toAccountType,
  }) {
    invalidateProvidersForTransactionUsing(
      _ref.invalidate,
      fromAccountType: fromAccountType,
      toAccountType: toAccountType,
    );
  }
}
