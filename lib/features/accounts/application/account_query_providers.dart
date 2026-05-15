import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/data/accounts/account_balance_query.dart';
import 'package:flowm/data/accounts/account_command_service.dart';
import 'package:flowm/data/accounts/account_tree_query.dart';
import 'package:flowm/features/accounts/application/account_presentation_mapper.dart';
import 'package:flowm/state/database/database_provider.dart';

final accountBalanceQueryProvider = Provider<AccountBalanceQuery>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  return AccountBalanceQuery(accountDao);
});

final accountTreeQueryProvider = Provider<AccountTreeQuery>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  final balanceQuery = ref.watch(accountBalanceQueryProvider);
  return AccountTreeQuery(accountDao, balanceQuery);
});

final accountCommandServiceProvider = Provider<AccountCommandService>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  return AccountCommandService(accountDao);
});

final accountPresentationMapperProvider =
    Provider<AccountPresentationMapper>((ref) {
  return const AccountPresentationMapper();
});
