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
    extends ConsumerState<AccountUpdateBottomSheet> {
  late AccountSelectorType _currentAccountType;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Account? _selectedParentAccount;
  bool _isDefaultAssetAccount = false;
  bool _hasChildAccounts = false;

  @override
  void initState() {
    super.initState();

    // 初始化账户名称
    _nameController.text = widget.accountToUpdate.name;

    // 固定使用当前账户的类型，不允许修改
    _currentAccountType = _getAccountSelectorType(widget.accountToUpdate.type);

    // 检查是否有子账户
    _hasChildAccounts = widget.accountToUpdate.children != null &&
        widget.accountToUpdate.children!.isNotEmpty;

    // 异步获取当前账户的完整信息（包括一级账户和默认状态）
    _initializeAccountData();
  }

  /// 初始化账户数据（包括一级账户和默认状态）
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
          // 如果有一级账户，获取一级账户信息
          final parentAccount = await accountRepository
              .getAccountById(dbAccount.parentAccountId!);

          if (parentAccount != null && mounted) {
            // 将数据库的Account转换为UI的Account
            setState(() {
              _selectedParentAccount = Account(
                id: parentAccount.accountId,
                name: parentAccount.accountName,
                amount: 0.0, // 一级账户选择不需要金额信息
                type: parentAccount.accountType,
                currencySymbol: '¥',
              );
            });
            print('已设置一级账户: ${_selectedParentAccount?.name}');
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

  String _getAccountTypeDisplayName(AccountSelectorType selectorType) {
    switch (selectorType) {
      case AccountSelectorType.asset:
        return '资产';
      case AccountSelectorType.liability:
        return '负债';
      case AccountSelectorType.expense:
        return '支出';
      case AccountSelectorType.income:
        return '收入';
      case AccountSelectorType.equity:
        return '权益';
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

      // 验证一级账户类型
      final currentAccountType =
          _getAccountTypeFromSelector(_currentAccountType);
      if (_selectedParentAccount != null &&
          _selectedParentAccount!.type != currentAccountType) {
        if (mounted) {
          SnackBarUtils.showOverlayWarning(context, '一级账户类型必须与当前账户类型一致');
        }
        return;
      }

      try {
        print(
            '开始更新账户: ID=${widget.accountToUpdate.id}, 名称=${_nameController.text.trim()}');

        await ref.read(accountRepositoryProvider).editAccount(
              accountId: widget.accountToUpdate.id,
              name: _nameController.text.trim(),
              type: _getAccountTypeFromSelector(_currentAccountType),
              ledgerId: selectedLedger.ledgerId,
              parentId: _selectedParentAccount?.id,
              isDefaultAsset:
                  _hasChildAccounts ? false : _isDefaultAssetAccount,
            );

        print('账户更新成功');

        // 刷新所有账户相关的provider
        invalidateProvidersForTransaction(ref,
            fromAccountType: widget.accountToUpdate.type,
            toAccountType: _getAccountTypeFromSelector(_currentAccountType));

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
            invalidateProvidersForTransaction(ref,
                accountType: widget.accountToUpdate.type);
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
          // 显示当前账户类型（只读）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '账户类型: ${_getAccountTypeDisplayName(_currentAccountType)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(编辑时不可修改)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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

                  // 设为默认资产账户选项（仅资产账户且无子账户时显示）
                  if (_currentAccountType == AccountSelectorType.asset &&
                      !_hasChildAccounts)
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

                  // 如果是有子账户的资产账户，显示提示信息
                  if (_currentAccountType == AccountSelectorType.asset &&
                      _hasChildAccounts)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '只有叶子节点（无子账户）才能设为默认资产账户',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // 一级账户选择区域
                  if (_hasChildAccounts)
                    // 有子账户时，显示禁用状态和提示信息
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.block,
                                  color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '无法设置一级账户',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '此账户有子账户，只能作为根节点存在',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // 无子账户时，允许选择一级账户
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            title: Text(
                                _selectedParentAccount?.name ?? '选择一级账户 (可选)'),
                            trailing: const Icon(Icons.keyboard_arrow_right),
                            onTap: () async {
                              final selectedAccount =
                                  await ParentAccountSelectorBottomSheet.show(
                                context,
                                title: '选择一级账户',
                                accountType: _currentAccountType,
                                selectedAccount: _selectedParentAccount,
                                onlyShowRootAccounts: true, // 只显示根节点账户
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
