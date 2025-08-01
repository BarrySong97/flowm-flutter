import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/common/account_selector_bottom_sheet.dart';
import 'package:flowm/components/common/parent_account_selector_bottom_sheet.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/snackbar_utils.dart';

class AccountUpdateBottomSheet extends ConsumerStatefulWidget {
  final Account accountToUpdate;

  const AccountUpdateBottomSheet({
    super.key,
    required this.accountToUpdate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Account accountToUpdate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AccountUpdateBottomSheet(
          accountToUpdate: accountToUpdate,
        ),
      ),
    );
  }

  @override
  ConsumerState<AccountUpdateBottomSheet> createState() =>
      _AccountUpdateBottomSheetState();
}

class _AccountUpdateBottomSheetState
    extends ConsumerState<AccountUpdateBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AccountSelectorType> _accountTypes;
  late List<String> _tabLabels;
  late AccountSelectorType _currentAccountType;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Account? _selectedParentAccount;
  bool _isDefaultAssetAccount = false;

  @override
  void initState() {
    super.initState();

    // 初始化账户名称
    _nameController.text = widget.accountToUpdate.name;

    _accountTypes = [
      AccountSelectorType.asset,
      AccountSelectorType.liability,
      AccountSelectorType.expense,
      AccountSelectorType.income,
      AccountSelectorType.equity,
    ];
    _tabLabels = ['资产', '负债', '支出', '收入', '权益'];

    // 根据当前账户类型确定初始tab
    _currentAccountType = _getAccountSelectorType(widget.accountToUpdate.type);
    int initialIndex = _accountTypes.indexOf(_currentAccountType);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
        length: _accountTypes.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 异步获取当前账户的完整信息（包括父账户和默认状态）
    _initializeAccountData();
  }

  /// 初始化账户数据（包括父账户和默认状态）
  Future<void> _initializeAccountData() async {
    try {
      // 从数据库获取当前账户的完整信息
      final accountRepository = ref.read(accountRepositoryProvider);
      final dbAccount =
          await accountRepository.getAccountById(widget.accountToUpdate.id);

      if (dbAccount != null && mounted) {
        setState(() {
          // 设置默认资产账户状态
          _isDefaultAssetAccount = dbAccount.defaultUseAssets ?? false;
        });

        if (dbAccount.parentAccountId != null) {
          // 如果有父账户，获取父账户信息
          final parentAccount =
              await accountRepository.getAccountById(dbAccount.parentAccountId!);

          if (parentAccount != null && mounted) {
            // 将数据库的Account转换为UI的Account
            setState(() {
              _selectedParentAccount = Account(
                id: parentAccount.accountId,
                name: parentAccount.accountName,
                amount: 0.0, // 父账户选择不需要金额信息
                type: parentAccount.accountType,
                currencySymbol: '¥',
              );
            });
            print('已设置父账户: ${_selectedParentAccount?.name}');
          }
        }
        
        print('已设置默认资产账户状态: $_isDefaultAssetAccount');
      }
    } catch (e) {
      print('获取账户信息失败: $e');
      // 如果获取失败，继续使用默认值
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  AccountSelectorType _getAccountSelectorType(AccountType accountType) {
    switch (accountType) {
      case AccountType.ASSET:
        return AccountSelectorType.asset;
      case AccountType.LIABILITY:
        return AccountSelectorType.liability;
      case AccountType.EXPENSE:
        return AccountSelectorType.expense;
      case AccountType.INCOME:
        return AccountSelectorType.income;
      case AccountType.EQUITY:
        return AccountSelectorType.equity;
    }
  }

  AccountType _getAccountTypeFromSelector(AccountSelectorType selectorType) {
    switch (selectorType) {
      case AccountSelectorType.asset:
        return AccountType.ASSET;
      case AccountSelectorType.liability:
        return AccountType.LIABILITY;
      case AccountSelectorType.expense:
        return AccountType.EXPENSE;
      case AccountSelectorType.income:
        return AccountType.INCOME;
      case AccountSelectorType.equity:
        return AccountType.EQUITY;
    }
  }

  Future<void> _updateAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedLedger = await ref.read(selectedLedgerProvider.future);
      if (selectedLedger == null) {
        if (mounted) {
          Navigator.of(context).pop(false); // 先关闭 bottom sheet
          // 延迟显示 snackbar 避免被遮挡
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              SnackBarUtils.showOverlayError(context, '错误：未选择任何账本');
            }
          });
        }
        return;
      }

      // 验证父账户类型
      final currentAccountType = _getAccountTypeFromSelector(_accountTypes[_tabController.index]);
      if (_selectedParentAccount != null && _selectedParentAccount!.type != currentAccountType) {
        if (mounted) {
          SnackBarUtils.showOverlayWarning(context, '父账户类型必须与当前账户类型一致');
        }
        return;
      }

      try {
        print(
            '开始更新账户: ID=${widget.accountToUpdate.id}, 名称=${_nameController.text.trim()}');

        await ref.read(accountRepositoryProvider).editAccount(
              accountId: widget.accountToUpdate.id,
              name: _nameController.text.trim(),
              type: _getAccountTypeFromSelector(
                  _accountTypes[_tabController.index]),
              ledgerId: selectedLedger.ledgerId,
              parentId: _selectedParentAccount?.id,
              isDefaultAsset: _isDefaultAssetAccount,
            );

        print('账户更新成功');

        // 刷新所有账户相关的provider
        invalidateProvidersForTransaction(ref,
            fromAccountType: widget.accountToUpdate.type,
            toAccountType: _getAccountTypeFromSelector(
                _accountTypes[_tabController.index]));

        if (mounted) {
          Navigator.of(context).pop(true); // Success
          // 延迟显示成功消息避免被遮挡
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              SnackBarUtils.showOverlaySuccess(context, '账户更新成功');
            }
          });
        }
      } catch (e, stackTrace) {
        print('更新账户失败: $e');
        print('堆栈跟踪: $stackTrace');

        if (mounted) {
          Navigator.of(context).pop(false);
          // 延迟显示错误消息避免被遮挡
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              SnackBarUtils.showOverlayError(context, '更新账户失败: $e');
            }
          });
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除账户 "${widget.accountToUpdate.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print(
            '开始删除账户: ID=${widget.accountToUpdate.id}, 名称=${widget.accountToUpdate.name}');

        final result = await ref
            .read(accountRepositoryProvider)
            .deleteAccount(widget.accountToUpdate.id);

        String message;
        Color backgroundColor;
        bool success = false;

        switch (result) {
          case DeleteAccountResult.success:
            message = '账户删除成功';
            backgroundColor = Colors.green;
            success = true;
            print('账户删除成功');

            // 刷新所有账户相关的provider
            invalidateProvidersForTransaction(ref, accountType: widget.accountToUpdate.type);
            break;

          case DeleteAccountResult.hasChildAccounts:
            message = '删除失败：该账户有子账户，请先删除子账户';
            backgroundColor = Colors.orange;
            print('删除失败：该账户可能有子账户');
            break;

          case DeleteAccountResult.hasRelatedTransactions:
            message = '删除失败：该账户有相关交易记录，请先删除相关的交易记录再删除账户';
            backgroundColor = Colors.orange;
            print('删除失败：该账户有相关的交易记录');
            break;

          case DeleteAccountResult.isSystemAccount:
            message = '无法删除系统账户"期初余额"，该账户用于维护复式记账平衡';
            backgroundColor = Colors.red;
            print('删除失败：该账户是系统保护账户');
            break;

          case DeleteAccountResult.error:
          default:
            message = '删除账户失败：未知错误';
            backgroundColor = Colors.red;
            print('删除账户失败：未知错误');
            break;
        }

        if (mounted) {
          print('准备显示消息: $message');

          // 先显示消息，再关闭bottom sheet
          switch (result) {
            case DeleteAccountResult.success:
              SnackBarUtils.showOverlaySuccess(context, message);
              break;
            case DeleteAccountResult.hasChildAccounts:
            case DeleteAccountResult.hasRelatedTransactions:
              SnackBarUtils.showOverlayWarning(context, message);
              break;
            case DeleteAccountResult.isSystemAccount:
              SnackBarUtils.showOverlayError(context, message);
              break;
            case DeleteAccountResult.error:
            default:
              SnackBarUtils.showOverlayError(context, message);
              break;
          }

          // 延迟关闭bottom sheet，让消息先显示
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.of(context).pop(success);
            }
          });
        }
      } catch (e, stackTrace) {
        print('删除账户失败: $e');
        print('堆栈跟踪: $stackTrace');

        if (mounted) {
          print('显示异常错误消息: 删除账户失败: $e');
          SnackBarUtils.showOverlayError(context, '删除账户失败: $e');

          // 延迟关闭bottom sheet
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.of(context).pop(false);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('更新账户', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteAccount,
                  tooltip: '删除账户',
                ),
              ],
            ),
          ),
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
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '账户名称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入账户名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 设为默认资产账户选项（仅资产账户显示）
                  if (_accountTypes[_tabController.index] == AccountSelectorType.asset)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: const Text('设为默认资产账户'),
                          subtitle: const Text('设置此账户为添加交易时的默认资产账户'),
                          value: _isDefaultAssetAccount,
                          onChanged: (value) {
                            setState(() {
                              _isDefaultAssetAccount = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          title: Text(
                              _selectedParentAccount?.name ?? '选择父账户 (可选)'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () async {
                            final selectedAccount =
                                await ParentAccountSelectorBottomSheet.show(
                              context,
                              title: '选择父账户',
                              accountType: _accountTypes[_tabController.index],
                              selectedAccount: _selectedParentAccount,
                            );
                            if (selectedAccount != null) {
                              setState(() {
                                _selectedParentAccount = selectedAccount;
                              });
                            }
                          },
                        ),
                      ),
                      if (_selectedParentAccount != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedParentAccount = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateAccount,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('更新账户'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
