import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/data/net_worth/net_worth_flow_query.dart';
import 'package:flowm/state/database/database_provider.dart';

final netWorthFlowQueryProvider = Provider<NetWorthFlowQuery>((ref) {
  return NetWorthFlowQuery(
    accountDao: ref.watch(accountDaoProvider),
    postingDao: ref.watch(postingDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
  );
});
