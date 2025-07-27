import 'package:flowm/components/common/popover_select.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/state/account/account_info_provider.dart'; // Re-add for Account model
import 'package:flowm/components/account/account_row.dart'; // Import AccountRow
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:flowm/components/common/account_update_bottom_sheet.dart';

class TopAssetsAccountDetailPage extends ConsumerStatefulWidget {
  final int accountId; // 接收 accountId 参数

  const TopAssetsAccountDetailPage(
      {super.key, required this.accountId}); // 修改构造函数

  @override
  ConsumerState<TopAssetsAccountDetailPage> createState() =>
      _TopAssetsAccountDetailPageState();
}

class _TopAssetsAccountDetailPageState
    extends ConsumerState<TopAssetsAccountDetailPage>
    with AutomaticKeepAliveClientMixin {
  String? _drilledDownAccountName; // State for current drill-down level
  bool _isAscending = true; // State for sort order
  // dynamic _currentAccount; // _currentAccount is assigned account but account is used directly.

  @override
  void initState() {
    super.initState();
    // _currentAccount = account; // account is directly accessible
    // if (account != null) { // Constructor requires account, so it should not be null.
    //   print('TopAssetsAccountDetailPage received account: ${account.name}');
    // }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    // 动态获取账户信息
    final accountAsync = ref.watch(accountInfoProvider(widget.accountId));

    return accountAsync.when(
      data: (account) => _buildDetailPage(context, account),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildDetailPage(BuildContext context, Account account) {
    // final topAssetsAsync = ref.watch(topAssetAccountsProvider); // Removed
    // final uiAccountsAsync = ref.watch(uiAccountsProvider); // Removed

    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: 'year', label: '本年'),
      // PopoverSelectItem(value: 'custom', label: '自定义'),
    ];

    final selectedDateRange = ref.watch(selectedDateRangeProvider);
    final subAccountsAsync = ref.watch(assetSubAccountTreeProvider(account.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F6FB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 22, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          account.name,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () async {
              final isDeleted = await AccountUpdateBottomSheet.show(
                context,
                accountToUpdate: account,
              );
              
              // 如果账户被删除，退出详情页面
              if (isDeleted == true && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFF5F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                // 总资产区域
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              // Consider changing '总资产' to something like '账户余额' or dynamically including account name
                              // if this page can show sub-account details. For now, keeping as is.
                              '总资产',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            PopoverSelect(
                              items: dateRangeOptions,
                              value: selectedDateRange, // Default to 'month'

                              onChanged: (value) {
                                // Update the selectedDateRangeProvider when PopoverSelect changes
                                ref
                                    .read(selectedDateRangeProvider.notifier)
                                    .state = value;
                              },
                            ),
                          ],
                        ),
                      ),
                      Consumer(builder: (context, ref, child) {
                        final assetTrendAsync = ref
                            .watch(assetTrendProviderByDateRange(account.id));

                        final amountWidget = Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: assetTrendAsync.when(
                            data: (assetData) {
                              final amount = assetData.isNotEmpty
                                  ? assetData.last.totalAssets
                                  : account.amount;
                              return Text(
                                '¥${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                            loading: () => const Text(
                              '计算中...',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            error: (e, s) => const Text(
                              '加载失败',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );

                        final chartWidget = assetTrendAsync.when(
                          data: (assetData) {
                            if (assetData.isEmpty) {
                              return const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: Text(
                                          '暂无该时间段资产趋势数据'))); // Updated message
                            }
                            return AssetTrendChart(assetData: assetData);
                          },
                          loading: () => const SizedBox(
                              height: 200,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          error: (error, stack) => SizedBox(
                              height: 200,
                              child: Center(child: Text('加载趋势图失败: $error'))),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            amountWidget,
                            chartWidget,
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                subAccountsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64.0),
                    child: Center(child: Text('加载子账户失败: $err')),
                  ),
                  data: (subAccounts) {
                    if (subAccounts.isEmpty) {
                      return Container(
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 48),
                          child: Center(child: Text('${account.name} 无下级账户')));
                    }
                    final double totalTopLevelAmount = subAccounts.fold(
                        0.0, (sum, account) => sum + account.amount.abs());

                    List<Account> accountsWithPercentage =
                        subAccounts.map((account) {
                      double percentage = totalTopLevelAmount == 0
                          ? 0.0
                          : (account.amount.abs() / totalTopLevelAmount) * 100;
                      return Account(
                        id: account.id,
                        name: account.name,
                        amount: account.amount,
                        icon: account.icon,
                        type: account.type,
                        children: account.children,
                        currencySymbol: account.currencySymbol,
                        percentage: percentage,
                      );
                    }).toList();

                    // Sort accounts based on _isAscending state
                    accountsWithPercentage.sort((a, b) {
                      if (_isAscending) {
                        return a.amount.compareTo(b.amount);
                      } else {
                        return b.amount.compareTo(a.amount);
                      }
                    });

                    return Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 资产分布标题
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '资产分布',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  Icon(
                                    _isAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  Text(
                                    _isAscending ? '升序' : '降序',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _isAscending = !_isAscending;
                                });
                              },
                            ),
                          ],
                        ),


                        // 资产分布图表
                        Container(
                          height: _drilledDownAccountName == null
                              ? 240
                              : 280, // Adjust height if back button is shown
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Builder(
                            // Using Builder to create a new context for modifications
                            builder: (context) {
                              final List<Account> treemapBaseData = subAccounts;

                              if (treemapBaseData.isEmpty) {
                                return Center(
                                    child: Text('${account.name} 无下级账户可供分布展示'));
                              }

                              List<Account> displayedAccounts;
                              String currentTreemapTitle;
                              bool isDrilledDown =
                                  _drilledDownAccountName != null;

                              if (!isDrilledDown) {
                                displayedAccounts = treemapBaseData;
                                currentTreemapTitle = '${account.name} - 资产构成';
                              } else {
                                final parentAccount =
                                    treemapBaseData.firstWhereOrNull((acc) =>
                                        acc.name == _drilledDownAccountName);

                                if (parentAccount != null &&
                                    parentAccount.children != null &&
                                    parentAccount.children!.isNotEmpty) {
                                  displayedAccounts = parentAccount.children!;
                                  currentTreemapTitle =
                                      '$_drilledDownAccountName - 资产构成';
                                } else {
                                  // Fallback: If parent not found or has no children, show base level and reset drill-down
                                  displayedAccounts = treemapBaseData;
                                  currentTreemapTitle =
                                      '${account.name} - 资产构成';
                                  _drilledDownAccountName = null;
                                  isDrilledDown = false;
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _drilledDownAccountName = null;
                                      });
                                    }
                                  });
                                }
                              }

                              final double totalValueAtThisLevel =
                                  displayedAccounts
                                      .where((account) => account.amount > 0)
                                      .fold(
                                          0.0,
                                          (sum, account) =>
                                              sum + account.amount);

                              final treeMapData = displayedAccounts
                                  .where((account) => account.amount > 0)
                                  .map((account) {
                                double? percentage;
                                if (totalValueAtThisLevel > 0) {
                                  percentage =
                                      (account.amount / totalValueAtThisLevel) *
                                          100;
                                }
                                return TreemapData(
                                  name: account.name,
                                  value: account.amount,
                                  canDrillDown: account.children != null &&
                                      account.children!.isNotEmpty,
                                  percentageOfLevel: percentage,
                                );
                              }).toList();

                              if (treeMapData.isEmpty) {
                                return Center(
                                    child: Text(isDrilledDown
                                        ? '此分类下无子账户数据'
                                        : '${account.name} 无可显示的下级资产数据'));
                              }

                              return Column(
                                // Wrap Treemap with a Column to add a back button
                                children: [
                                  if (isDrilledDown)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8.0, left: 8.0, right: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(
                                                Icons.arrow_back_ios,
                                                size: 16),
                                            label: Text(
                                                '返回 ${account.name}'), // Clarify back destination
                                            onPressed: () {
                                              setState(() {
                                                _drilledDownAccountName = null;
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          // Spacer(),
                                          // Text(currentTreemapTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                      child: TreemapWidget(
                                        key: ValueKey(_drilledDownAccountName ??
                                            account.name), // Simpler key
                                        title: currentTreemapTitle,
                                        dataItems: treeMapData,
                                        tooltipValueSuffix: ' ¥',
                                        drilledDownAccountName:
                                            _drilledDownAccountName,
                                        onDrillDownSelected: (accountName) {
                                          final selectedAccount =
                                              displayedAccounts
                                                  .firstWhereOrNull((acc) =>
                                                      acc.name == accountName);

                                          if (selectedAccount != null &&
                                              selectedAccount.children !=
                                                  null &&
                                              selectedAccount
                                                  .children!.isNotEmpty) {
                                            setState(() {
                                              _drilledDownAccountName =
                                                  accountName;
                                            });
                                          } else {
                                            print(
                                                'Cannot drill down: $accountName has no children or was not found in the current view.');
                                          }
                                        },
                                        onDoubleClick: (accountName) {
                                          final selectedAccountToNavigate =
                                              displayedAccounts
                                                  .firstWhereOrNull((acc) =>
                                                      acc.name == accountName);
                                          if (selectedAccountToNavigate !=
                                              null) {
                                            print(
                                                '双击 $accountName, 准备导航到详情页 for account: ${selectedAccountToNavigate.name}');
                                            bool hasChildren =
                                                selectedAccountToNavigate
                                                            .children !=
                                                        null &&
                                                    selectedAccountToNavigate
                                                        .children!.isNotEmpty;
                                            if (hasChildren) {
                                              GoRouter.of(context).pushNamed(
                                                  'topAssetsAccountDetail',
                                                  extra: {
                                                    'accountId':
                                                        selectedAccountToNavigate
                                                            .id
                                                  });
                                            } else {
                                              GoRouter.of(context).pushNamed(
                                                  'assetsDetail', // Navigate to accountDetail if no children
                                                  extra: {
                                                    'accountId':
                                                        selectedAccountToNavigate
                                                            .id
                                                  });
                                            }
                                          } else {}
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: accountsWithPercentage
                                .length, // Use the new list
                            itemBuilder: (context, index) {
                              return AccountRow(
                                account: accountsWithPercentage[index],
                                percentage:
                                    accountsWithPercentage[index].percentage,
                                showCurrencySymbolInAmount:
                                    false, // Pass account with percentage
                                onTap: (account) {
                                  // 实现和treemap相同的导航逻辑
                                  bool hasChildren = account.children != null &&
                                      account.children!.isNotEmpty;
                                  if (hasChildren) {
                                    GoRouter.of(context).pushNamed(
                                        'topAssetsAccountDetail',
                                        extra: {'accountId': account.id});
                                  } else {
                                    GoRouter.of(context).pushNamed(
                                        'assetsDetail', // Navigate to assetsDetail if no children
                                        extra: {'accountId': account.id});
                                  }
                                },
                              );
                            },
                          ),
                        )
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
