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
  final _initialAmountController = TextEditingController();
  Account? _selectedParentAccount;
  bool _hasInitialAmount = true;
  bool _isDefaultAssetAccount = false;

  @override
  void initState() {
    super.initState();

    // 设置初始金额默认值为0
    _initialAmountController.text = '0';

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
        setState(() {
          // 当切换账户类型时，重置初始金额状态
          if (!_shouldShowInitialAmount()) {
            _hasInitialAmount = false;
            _initialAmountController.clear();
          } else {
            // 如果切换到需要显示初始金额的账户类型，恢复默认值0
            if (_initialAmountController.text.isEmpty) {
              _initialAmountController.text = '0';
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _initialAmountController.dispose();
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

  /// 判断当前账户类型是否应该显示初始金额选项
  bool _shouldShowInitialAmount() {
    final currentType = _accountTypes[_tabController.index];
    return currentType == AccountSelectorType.asset ||
        currentType == AccountSelectorType.liability;
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

      // 检查账户层级限制：如果选择的一级账户还有一级账户，则不能创建
      if (_selectedParentAccount != null) {
        final parentAccount = await ref
            .read(accountRepositoryProvider)
            .getAccountById(_selectedParentAccount!.id);

        if (parentAccount != null && parentAccount.parentAccountId != null) {
          if (mounted) {
            SnackBarUtils.showOverlayError(
                context, '不能创建账户：所选一级账户已经是子账户，只支持两级账户层级');
          }
          return;
        }
      }

      try {
        // 解析初始金额
        double? initialAmount;
        if (_hasInitialAmount && _initialAmountController.text.isNotEmpty) {
          initialAmount = double.tryParse(_initialAmountController.text.trim());
          if (initialAmount == null || initialAmount < 0) {
            if (mounted) {
              SnackBarUtils.showOverlayError(context, '初始金额必须为正数');
            }
            return;
          }
        }

        // 根据是否有初始金额选择创建方法
        if (initialAmount != null && initialAmount > 0) {
          await ref
              .read(accountRepositoryProvider)
              .addNewAccountWithInitialAmount(
                name: _nameController.text.trim(),
                type: _getAccountTypeFromSelector(
                    _accountTypes[_tabController.index]),
                ledgerId: selectedLedger.ledgerId,
                parentId: _selectedParentAccount?.id,
                initialAmount: initialAmount,
                isDefaultAsset: _isDefaultAssetAccount,
              );
        } else {
          await ref.read(accountRepositoryProvider).addNewAccount(
                name: _nameController.text.trim(),
                type: _getAccountTypeFromSelector(
                    _accountTypes[_tabController.index]),
                ledgerId: selectedLedger.ledgerId,
                parentId: _selectedParentAccount?.id,
                isDefaultAsset: _isDefaultAssetAccount,
              );
        }

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
    final selectedLedger = ref.watch(selectedLedgerProvider).value;
    // 根据账户类型调整高度：资产和负债类型需要显示初始金额，因此高度更高
    final currentAccountType = _accountTypes[_tabController.index];
    final bool isAssetOrLiability =
        currentAccountType == AccountSelectorType.asset ||
            currentAccountType == AccountSelectorType.liability;
    final double heightRatio = isAssetOrLiability ? 0.61 : 0.48;

    return Container(
      height: MediaQuery.of(context).size.height * heightRatio,
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
                  // 初始金额设置（仅对资产和负债账户显示）
                  if (_shouldShowInitialAmount())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Column(
                          children: [
                            TextFormField(
                              controller: _initialAmountController,
                              decoration: InputDecoration(
                                labelText: '初始金额',
                                prefixText: '${selectedLedger?.currencySymbol ?? '¥'} ',
                                border: const OutlineInputBorder(),
                                // helperText: '设置此账户的当前余额',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (_hasInitialAmount &&
                                    (value == null || value.trim().isEmpty)) {
                                  return '请输入初始金额';
                                }
                                if (_hasInitialAmount && value != null) {
                                  final amount = double.tryParse(value.trim());
                                  if (amount == null || amount < 0) {
                                    return '初始金额必须为正数';
                                  }
                                  if (amount > 1000000000) {
                                    return '初始金额不能超过10亿';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),

                  // 设为默认资产账户选项（仅资产账户显示）
                  if (_accountTypes[_tabController.index] ==
                      AccountSelectorType.asset)
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
                      ],
                    ),

                  // 提示文字

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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '系统最多支持两层账户结构，选择一级账户作为一级账户',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
