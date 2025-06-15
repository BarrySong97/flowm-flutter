import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_creation_bottom_sheet.dart';
import 'package:flowm/components/common/account_selector_item.dart';
import 'package:flowm/state/account/account_repository.dart';

enum AccountSelectorType {
  asset,
  liability,
  expense,
  income,
  equity,
}

enum SelectableAccount {
  all,
  leafOnly,
}

class AccountSelectorBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final Account? selectedAccount;
  final Function(Account) onAccountSelected;
  final AccountSelectorType? defaultAccountType;
  final SelectableAccount selectableAccount;

  const AccountSelectorBottomSheet({
    super.key,
    required this.title,
    this.selectedAccount,
    required this.onAccountSelected,
    this.defaultAccountType,
    this.selectableAccount = SelectableAccount.all,
  });

  static Future<Account?> show(
    BuildContext context, {
    required String title,
    Account? selectedAccount,
    AccountSelectorType? defaultAccountType,
    SelectableAccount selectableAccount = SelectableAccount.all,
  }) {
    return showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AccountSelectorBottomSheet(
        title: title,
        selectedAccount: selectedAccount,
        defaultAccountType: defaultAccountType,
        selectableAccount: selectableAccount,
        onAccountSelected: (account) {
          Navigator.of(context).pop(account);
        },
      ),
    );
  }

  @override
  ConsumerState<AccountSelectorBottomSheet> createState() =>
      _AccountSelectorBottomSheetState();
}

class _AccountSelectorBottomSheetState
    extends ConsumerState<AccountSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AccountSelectorType> _accountTypes;
  late List<String> _tabLabels;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _accountTypes = [
      AccountSelectorType.asset,
      AccountSelectorType.liability,
      AccountSelectorType.expense,
      AccountSelectorType.income,
      AccountSelectorType.equity,
    ];

    _tabLabels = ['资产', '负债', '费用', '收入', '权益'];

    // 确定初始tab索引
    int initialIndex = 0;
    if (widget.defaultAccountType != null) {
      initialIndex = _accountTypes.indexOf(widget.defaultAccountType!);
      if (initialIndex == -1) initialIndex = 0;
    }

    // 初始创建 TabController
    _tabController = TabController(
      length: _accountTypes.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    // 添加监听器以触发动画更新
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 如果有selectedAccount，异步确定正确的tab并切换
    if (widget.selectedAccount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _findAndSwitchToAccountTab();
      });
    }
  }

  Future<void> _findAndSwitchToAccountTab() async {
    if (widget.selectedAccount == null) return;

    try {
      final correctIndex = await _findAccountTypeIndex(widget.selectedAccount!);
      if (mounted && _tabController.index != correctIndex) {
        _tabController.animateTo(correctIndex);
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('切换账户类型tab失败: $e');
      // 失败时保持当前tab
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // 异步查找账户在哪个类型的provider中
  Future<int> _findAccountTypeIndex(Account account) async {
    try {
      // 检查各个provider中是否包含该账户
      final providers = [
        assetsAccountTreeProvider,
        liabilityAccountTreeProvider,
        expenseAccountTreeProvider,
        incomeAccountTreeProvider,
        equityAccountTreeProvider,
      ];

      for (int i = 0; i < providers.length; i++) {
        try {
          final accounts = await ref.read(providers[i].future);
          if (_findAccountInList(accounts, account.id)) {
            return i;
          }
        } catch (e) {
          // 如果某个provider加载失败，继续检查下一个
          continue;
        }
      }
    } catch (e) {
      // 如果异步查找失败，使用基于名称的推断
      print('查找账户类型失败: $e');
    }

    // fallback：使用基于名称的推断
    return _getAccountTypeIndexByName(account);
  }

  // 在账户列表中递归查找指定ID的账户
  bool _findAccountInList(List<Account> accounts, int accountId) {
    for (final account in accounts) {
      if (account.id == accountId) {
        return true;
      }
      if (account.children != null) {
        if (_findAccountInList(account.children!, accountId)) {
          return true;
        }
      }
    }
    return false;
  }

  // 根据账户推测其类型在tab中的索引
  int _getAccountTypeIndexByName(Account account) {
    final accountName = account.name.toLowerCase();

    // 简单的规则匹配来推断账户类型
    if (accountName.contains('现金') ||
        accountName.contains('银行') ||
        accountName.contains('储蓄') ||
        accountName.contains('投资') ||
        accountName.contains('基金') ||
        accountName.contains('股票') ||
        accountName.contains('支付宝') ||
        accountName.contains('微信') ||
        accountName.contains('余额')) {
      return 0; // 资产
    } else if (accountName.contains('信用卡') ||
        accountName.contains('贷款') ||
        accountName.contains('借款') ||
        accountName.contains('负债')) {
      return 1; // 负债
    } else if (accountName.contains('支出') ||
        accountName.contains('费用') ||
        accountName.contains('开销') ||
        accountName.contains('餐饮') ||
        accountName.contains('交通') ||
        accountName.contains('购物')) {
      return 2; // 费用
    } else if (accountName.contains('收入') ||
        accountName.contains('薪资') ||
        accountName.contains('奖金') ||
        accountName.contains('工资')) {
      return 3; // 收入
    } else if (accountName.contains('权益') || accountName.contains('资本')) {
      return 4; // 权益
    }

    // 默认返回资产类型
    return 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title and Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.blue, size: 28),
                  onPressed: () async {
                    final currentAccountType =
                        _accountTypes[_tabController.index];
                    await AccountCreationBottomSheet.show(
                      context,
                      defaultAccountType: currentAccountType,
                    );
                  },
                  tooltip: '创建新账户',
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _tabLabels.length,
                (index) => GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 50,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: _tabController.index == index ? 18 : 14,
                        fontWeight: _tabController.index == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _tabController.index == index
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                      child: Text(
                        _tabLabels[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 分割线
          Divider(
            height: 1,
            color: Colors.grey[200],
          ),

          // Account list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _accountTypes.map((accountType) {
                return _buildAccountListTab(accountType);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountListTab(AccountSelectorType accountType) {
    final accountsAsync = _getAccountProvider(accountType);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return const Center(
            child: Text('暂无账户数据'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: _buildAccountList(accounts),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  // 根据账户类型选择对应的provider
  AsyncValue<List<Account>> _getAccountProvider(
      AccountSelectorType accountType) {
    switch (accountType) {
      case AccountSelectorType.asset:
        return ref.watch(assetsAccountTreeProvider);
      case AccountSelectorType.liability:
        return ref.watch(liabilityAccountTreeProvider);
      case AccountSelectorType.expense:
        return ref.watch(expenseAccountTreeProvider);
      case AccountSelectorType.income:
        return ref.watch(incomeAccountTreeProvider);
      case AccountSelectorType.equity:
        return ref.watch(equityAccountTreeProvider);
    }
  }

  List<Widget> _buildAccountList(List<Account> accounts) {
    return accounts.map((account) {
      // 检查当前账户是否被选中（只有叶子节点才能被选中）
      final bool hasChildren =
          account.children != null && account.children!.isNotEmpty;
      final bool isAccountSelected =
          !hasChildren && _isAccountSelected(account);
      // 检查是否需要自动展开（当选中的账户是该账户的子账户时）
      final bool shouldAutoExpand = _shouldAutoExpand(account);

      return AccountSelectorItem(
        account: account,
        isSelected: isAccountSelected,
        shouldAutoExpand: shouldAutoExpand,
        selectedAccount: widget.selectedAccount, // 传递选中账户用于子账户选中状态判断
        onTap: (selectedAccount) {
          if (widget.selectableAccount == SelectableAccount.leafOnly &&
              hasChildren) {
            // 如果只允许选择叶子节点，且当前是父节点，则不响应点击
            return;
          }
          widget.onAccountSelected(selectedAccount);
        },
      );
    }).toList();
  }

  // 检查账户是否被选中
  bool _isAccountSelected(Account account) {
    if (widget.selectedAccount == null) return false;
    return widget.selectedAccount!.id == account.id;
  }

  // 检查是否需要自动展开（如果选中的账户是该账户的子账户）
  bool _shouldAutoExpand(Account account) {
    if (widget.selectedAccount == null) return false;
    if (account.children == null) return false;

    // 递归检查子账户中是否包含选中的账户
    return _containsSelectedAccount(account.children!, widget.selectedAccount!);
  }

  // 递归检查子账户列表中是否包含指定的账户
  bool _containsSelectedAccount(
      List<Account> children, Account selectedAccount) {
    for (final child in children) {
      if (child.id == selectedAccount.id) {
        return true;
      }
      if (child.children != null) {
        if (_containsSelectedAccount(child.children!, selectedAccount)) {
          return true;
        }
      }
    }
    return false;
  }
}

/*
使用示例：

// 显示账户选择器，默认选中资产类型
final selectedAccount = await AccountSelectorBottomSheet.show(
  context,
  title: '选择账户',
  defaultAccountType: AccountSelectorType.asset,
  selectedAccount: currentAccount, // 可选的当前选中账户  
);

// 显示账户选择器，默认选中费用类型
final selectedAccount = await AccountSelectorBottomSheet.show(
  context,
  title: '选择账户',
  defaultAccountType: AccountSelectorType.expense,
);

// 显示账户选择器，默认选中第一个tab（资产）
final selectedAccount = await AccountSelectorBottomSheet.show(
  context,
  title: '选择账户',
);
*/
