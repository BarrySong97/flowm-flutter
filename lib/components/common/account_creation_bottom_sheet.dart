import 'dart:ui';
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

class AccountCreationBottomSheet extends ConsumerStatefulWidget {
  final AccountSelectorType defaultAccountType;

  const AccountCreationBottomSheet({
    super.key,
    this.defaultAccountType = AccountSelectorType.asset,
  });

  static Future<bool?> show(
    BuildContext context, {
    AccountSelectorType defaultAccountType = AccountSelectorType.asset,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AccountCreationBottomSheet(
          defaultAccountType: defaultAccountType,
        ),
      ),
    );
  }

  @override
  ConsumerState<AccountCreationBottomSheet> createState() =>
      _AccountCreationBottomSheetState();
}

class _AccountCreationBottomSheetState
    extends ConsumerState<AccountCreationBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AccountSelectorType> _accountTypes;
  late List<String> _tabLabels;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Account? _selectedParentAccount;

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
    _tabLabels = ['资产', '负债', '支出', '收入', '权益'];

    int initialIndex = _accountTypes.indexOf(widget.defaultAccountType);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
        length: _accountTypes.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
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

  Future<void> _createAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedLedger = await ref.read(selectedLedgerProvider.future);
      if (selectedLedger == null) {
        if (mounted) {
          SnackBarUtils.showOverlayError(context, '错误：未选择任何账本');
        }
        return;
      }

      // 检查账户层级限制：如果选择的父账户还有父账户，则不能创建
      if (_selectedParentAccount != null) {
        final parentAccount = await ref
            .read(accountRepositoryProvider)
            .getAccountById(_selectedParentAccount!.id);

        if (parentAccount != null && parentAccount.parentAccountId != null) {
          if (mounted) {
            SnackBarUtils.showOverlayError(
                context, '不能创建账户：所选父账户已经是子账户，只支持两级账户层级');
          }
          return;
        }
      }

      try {
        await ref.read(accountRepositoryProvider).addNewAccount(
              name: _nameController.text.trim(),
              type: _getAccountTypeFromSelector(
                  _accountTypes[_tabController.index]),
              ledgerId: selectedLedger.ledgerId,
              parentId: _selectedParentAccount?.id,
            );

        invalidateProvidersForTransaction(ref,
            fromAccountType: _getAccountTypeFromSelector(
                _accountTypes[_tabController.index]),
            toAccountType: _getAccountTypeFromSelector(
                _accountTypes[_tabController.index]));

        if (mounted) {
          Navigator.of(context).pop(true); // Success
          // 延迟显示成功消息
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              SnackBarUtils.showOverlaySuccess(context, '账户创建成功');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showOverlayError(context, '创建账户失败: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
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
            child: Text('创建新账户', style: Theme.of(context).textTheme.titleLarge),
          ),
          AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              final targetIndex = _tabController.index;
              final previousIndex = _tabController.previousIndex;
              final animationValue = _tabController.animation!.value;

              final isJump = (targetIndex - previousIndex).abs() > 1;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_tabLabels.length, (index) {
                    double selectedness;

                    if (isJump) {
                      if (targetIndex == previousIndex) {
                        selectedness = index == targetIndex ? 1.0 : 0.0;
                      } else {
                        final double progress =
                            (animationValue - previousIndex) /
                                (targetIndex - previousIndex);
                        if (index == targetIndex) {
                          selectedness = progress;
                        } else if (index == previousIndex) {
                          selectedness = 1.0 - progress;
                        } else {
                          selectedness = 0.0;
                        }
                      }
                    } else {
                      selectedness = (1.0 - (animationValue - index).abs());
                    }

                    selectedness = selectedness.clamp(0.0, 1.0);

                    final Color color = Color.lerp(
                        Colors.grey[600], Colors.black, selectedness)!;
                    final FontWeight fontWeight = FontWeight.lerp(
                        FontWeight.w500, FontWeight.bold, selectedness)!;
                    final double scale =
                        lerpDouble(14.0 / 16.0, 1.0, selectedness)!;

                    return GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        width: 60,
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Transform.scale(
                          scale: scale,
                          child: Text(
                            _tabLabels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: fontWeight,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
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
                  ElevatedButton(
                    onPressed: _createAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('创建账户'),
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
