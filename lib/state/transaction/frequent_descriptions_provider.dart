import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_repository.dart';
import '../ledger/ledger_repository.dart';

/// 高频交易描述（备注）提供者
/// 
/// 获取当前账本中最常使用的交易描述，
/// 用于快速选择和填充
final frequentDescriptionsProvider = FutureProvider.autoDispose<
    List<({String description, int count})>>((ref) async {
  // 监听选中的账本变化
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  
  // 获取交易仓库
  final repository = ref.watch(transactionRepositoryProvider);
  
  // 获取高频描述
  return repository.getFrequentDescriptions(
    ledgerId: selectedLedger?.ledgerId,
    limit: 10,
  );
});