import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/data/cashflow/cashflow_query.dart';
import 'package:flowm/state/database/database_provider.dart';

final cashflowQueryProvider = Provider<CashflowQuery>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return CashflowQuery(postingDao);
});
