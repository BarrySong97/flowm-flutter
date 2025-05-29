import 'package:flowm/components/common/popover_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/liability_trend_chart.dart';
import 'package:flowm/components/chart/liability_treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model
import 'package:flowm/state/liabilities/liabilities_repository.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart'; // 引入 GoRouter

class LiabilitiesPage extends ConsumerStatefulWidget {
  const LiabilitiesPage({super.key});

  @override
  ConsumerState<LiabilitiesPage> createState() => _LiabilitiesPageState();
}

class _LiabilitiesPageState extends ConsumerState<LiabilitiesPage>
    with AutomaticKeepAliveClientMixin {
  String? _drilledDownAccountName; // State for current drill-down level

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    // 使用topLiabilitiesAsync代替直接调用repository
    final topLiabilitiesAsync = ref.watch(topLiabilityAccountsProvider);
    // 使用uiLiabilitiesAsync获取UI格式的账户数据
    final uiLiabilitiesAsync = ref.watch(uiLiabilityAccountsProvider);

    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: 'year', label: '本年'),
      // PopoverSelectItem(value: 'custom', label: '自定义'),
    ];
    final selectedDateRange = ref.watch(selectedDateRangeProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // 总负债区域
            Container(
              padding: EdgeInsets.only(top: 16),
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '总负债',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        PopoverSelect(
                          items: dateRangeOptions,
                          value: selectedDateRange,
                          onChanged: (value) {
                            // Update the selectedDateRangeProvider when PopoverSelect changes
                            ref.read(selectedDateRangeProvider.notifier).state =
                                value;
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: topLiabilitiesAsync.when(
                      data: (accounts) {
                        final totalLiabilities = accounts.fold(
                            0.0, (sum, account) => sum + account.balance);
                        return Text(
                          '¥${totalLiabilities.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () => const Text(
                        '加载中...',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '加载错误',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  // AssetTrendChart()
                  // Watch the liability trend provider by date range
                  Consumer(builder: (context, ref, child) {
                    final liabilityTrendAsync =
                        ref.watch(liabilityTrendProviderByDateRange(null));
                    return liabilityTrendAsync.when(
                      data: (liabilityData) {
                        if (liabilityData.isEmpty) {
                          return const SizedBox(
                              height: 140,
                              child: Center(child: Text('暂无该时间段负债趋势数据')));
                        }
                        return LiabilityTrendChart(
                            liabilityData: liabilityData);
                      },
                      loading: () => const SizedBox(
                          height: 140,
                          child: Center(child: CircularProgressIndicator())),
                      error: (error, stack) => SizedBox(
                          height: 140,
                          child: Center(child: Text('加载趋势图失败: $error'))),
                    );
                  }),
                ],
              ),
            ),

            // 负债分布标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '负债分布',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            // 负债分布图表
            Container(
              height: _drilledDownAccountName == null
                  ? 240
                  : 280, // Adjust height if back button is shown
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.hardEdge,
              child: uiLiabilitiesAsync.when(
                data: (allAccounts) {
                  // Renamed to allAccounts for clarity
                  if (allAccounts.isEmpty) {
                    return Center(child: Text('暂无负债数据'));
                  }

                  List<dynamic>
                      displayedAccounts; // Assuming 'dynamic' for now, replace with your Account model type
                  String currentTreemapTitle = '负债分布';
                  bool isDrilledDown = _drilledDownAccountName != null;

                  if (!isDrilledDown) {
                    displayedAccounts = allAccounts;
                  } else {
                    final parentAccount = allAccounts.firstWhereOrNull(
                        (acc) => acc.name == _drilledDownAccountName);

                    if (parentAccount != null &&
                        parentAccount.children != null &&
                        parentAccount.children!.isNotEmpty) {
                      displayedAccounts = parentAccount.children!;
                      currentTreemapTitle = '负债分布 > $_drilledDownAccountName';
                    } else {
                      // Fallback: If parent not found or has no children, show top level and reset drill-down
                      displayedAccounts = allAccounts;
                      _drilledDownAccountName = null;
                      isDrilledDown = false; // Update status
                      // Optionally, show a message or log this case
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _drilledDownAccountName = null;
                          });
                        }
                      });
                    }
                  }

                  // Calculate total value for the current level for percentage calculation
                  final double totalValueAtThisLevel = displayedAccounts
                      .where((account) => account.amount > 0)
                      .fold(0.0, (sum, account) => sum + account.amount);

                  final treeMapData = displayedAccounts
                      .where((account) => account.amount > 0)
                      .map((account) {
                    double? percentage;
                    if (totalValueAtThisLevel > 0) {
                      percentage =
                          (account.amount / totalValueAtThisLevel) * 100;
                    }
                    return LiabilityTreemapData(
                      name: account.name,
                      value: account.amount,
                      canDrillDown: account.children != null &&
                          account.children!.isNotEmpty,
                      percentageOfLevel: percentage,
                    );
                  }).toList();

                  if (treeMapData.isEmpty) {
                    return Center(
                        child:
                            Text(isDrilledDown ? '此分类下无子账户数据' : '暂无可显示的负债数据'));
                  }

                  return Column(
                    children: [
                      if (isDrilledDown)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, left: 8.0, right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: Icon(Icons.arrow_back_ios, size: 16),
                                label: Text('返回上一级'),
                                onPressed: () {
                                  setState(() {
                                    _drilledDownAccountName = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          child: LiabilityTreemapWidget(
                            key: ValueKey(
                                _drilledDownAccountName ?? '__treemap_root__'),
                            title: currentTreemapTitle,
                            dataItems: treeMapData,
                            tooltipValueSuffix: ' ¥',
                            drilledDownAccountName: _drilledDownAccountName,
                            onDrillDownSelected: (accountName) {
                              final selectedAccount =
                                  displayedAccounts.firstWhereOrNull(
                                      (acc) => acc.name == accountName);

                              if (selectedAccount != null &&
                                  selectedAccount.children != null &&
                                  selectedAccount.children!.isNotEmpty) {
                                setState(() {
                                  _drilledDownAccountName = accountName;
                                });
                              }
                            },
                            onDoubleClick: (accountName) {
                              final selectedAccountToNavigate =
                                  displayedAccounts.firstWhereOrNull(
                                      (acc) => acc.name == accountName);
                              if (selectedAccountToNavigate != null) {
                                bool hasChildren =
                                    selectedAccountToNavigate.children !=
                                            null &&
                                        selectedAccountToNavigate
                                            .children!.isNotEmpty;
                                if (hasChildren) {
                                  GoRouter.of(context).pushNamed(
                                      'topLiabilitiesAccountDetail',
                                      extra: {
                                        'account': selectedAccountToNavigate
                                      });
                                } else {
                                  GoRouter.of(context).pushNamed(
                                      'assetsLiabilityDetail',
                                      extra: {
                                        'account': selectedAccountToNavigate
                                      });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('加载数据失败: $err'),
                ),
              ),
            ),

            // 账户列表，使用从数据库获取的UI格式账户数据
            uiLiabilitiesAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('暂无账户数据'),
                    ),
                  );
                }

                // Calculate total amount for top-level accounts for percentage calculation
                final double totalTopLevelAmount = accounts.fold(
                    0.0, (sum, account) => sum + account.amount.abs());

                final List<Account> accountsWithPercentage =
                    accounts.map((account) {
                  double percentage = totalTopLevelAmount == 0
                      ? 0.0
                      : (account.amount.abs() / totalTopLevelAmount) * 100;
                  return Account(
                    id: account.id,
                    name: account.name,
                    amount: account.amount,
                    icon: account.icon,
                    children: account
                        .children, // Children percentages are handled within AccountItem
                    currencySymbol: account.currencySymbol,
                    percentage:
                        percentage, // Assign calculated top-level percentage
                  );
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accountsWithPercentage.length, // Use the new list
                  itemBuilder: (context, index) {
                    return AccountItem(
                      account: accountsWithPercentage[index],
                      onTap: (account) {
                        // 实现和treemap相同的导航逻辑
                        bool hasChildren = account.children != null &&
                            account.children!.isNotEmpty;
                        if (hasChildren) {
                          GoRouter.of(context).pushNamed(
                              'topLiabilitiesAccountDetail',
                              extra: {'account': account});
                        } else {
                          GoRouter.of(context).pushNamed(
                              'liabilitiesDetail', // Navigate to assetsDetail if no children
                              extra: {'account': account});
                        }
                      },
                    ); // Pass account with percentage
                  },
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('加载账户数据失败: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
