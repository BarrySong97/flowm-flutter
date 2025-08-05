import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/db/tables/account_table.dart';

/// 动态获取账户信息的 Provider
/// 用于替代静态传递的账户对象，确保账户信息（如余额）实时更新
final accountInfoProvider = FutureProvider.family<Account, int>((ref, accountId) async {
  final repository = ref.watch(accountRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  
  // 获取账户基本信息
  final accounts = await repository.getAllAccounts();
  final account = accounts.firstWhere(
    (acc) => acc.accountId == accountId,
    orElse: () => throw Exception('Account not found: $accountId'),
  );
  
  // 获取最新余额
  final balance = await repository.getAccountBalance(accountId);
  
  // 返回包含最新余额的账户对象
  return Account(
    id: account.accountId,
    name: account.accountName,
    amount: balance,
    type: account.accountType,
    icon: null, // 图标信息如果需要可以从其他地方获取
    children: null, // 子账户信息在详情页面一般不需要
    currencySymbol: selectedLedger?.currencySymbol ?? '¥',
  );
});

/// 动态获取支出/收入账户节点信息的 Provider
/// 用于支出和收入详情页面的动态数据获取
final accountExpenseNodeProvider = FutureProvider.family<AccountExpenseNode, int>((ref, accountId) async {
  final repository = ref.watch(accountRepositoryProvider);
  
  // 获取账户基本信息
  final accounts = await repository.getAllAccounts();
  final account = accounts.firstWhere(
    (acc) => acc.accountId == accountId,
    orElse: () => throw Exception('Account not found: $accountId'),
  );
  
  // 获取最新余额
  final balance = await repository.getAccountBalance(accountId);
  
  // 返回 AccountExpenseNode 对象
  return AccountExpenseNode(
    accountData: account,
    balance: balance,
    children: [], // 子账户信息可以根据需要获取
  );
});

/// 动态获取完整的账户树形结构信息的 Provider
/// 用于需要包含子账户信息的页面
final accountTreeInfoProvider = FutureProvider.family<Account, int>((ref, accountId) async {
  final repository = ref.watch(accountRepositoryProvider);
  
  // 获取当前选中的账本
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) {
    throw Exception('No ledger selected');
  }
  
  // 根据账户类型获取对应的树形结构
  final accounts = await repository.getAllAccounts();
  final account = accounts.firstWhere(
    (acc) => acc.accountId == accountId,
    orElse: () => throw Exception('Account not found: $accountId'),
  );
  
  List<Account>? children;
  
  // 递归查找账户的辅助函数
  Account? findAccountInTree(List<Account> tree, int targetId) {
    for (final acc in tree) {
      if (acc.id == targetId) {
        return acc;
      }
      if (acc.children != null) {
        final found = findAccountInTree(acc.children!, targetId);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }
  
  // 如果需要子账户信息，可以在这里获取
  if (account.accountType == AccountType.ASSET) {
    try {
      final assetTree = await repository.getAssetsAccountTree(ledgerId: selectedLedger.ledgerId);
      final parentAccount = findAccountInTree(assetTree, accountId);
      if (parentAccount != null) {
        children = parentAccount.children;
      }
    } catch (e) {
      print('Warning: Could not find account $accountId in asset tree: $e');
      // 继续执行，只是没有子账户信息
    }
  } else if (account.accountType == AccountType.LIABILITY) {
    try {
      final liabilityTree = await repository.getLiabilityAccountTree(ledgerId: selectedLedger.ledgerId);
      final parentAccount = findAccountInTree(liabilityTree, accountId);
      if (parentAccount != null) {
        children = parentAccount.children;
      }
    } catch (e) {
      print('Warning: Could not find account $accountId in liability tree: $e');
      // 继续执行，只是没有子账户信息
    }
  }
  
  // 获取最新余额
  final balance = await repository.getAccountBalance(accountId);
  
  return Account(
    id: account.accountId,
    name: account.accountName,
    amount: balance,
    type: account.accountType,
    icon: null,
    children: children,
    currencySymbol: selectedLedger.currencySymbol,
  );
});