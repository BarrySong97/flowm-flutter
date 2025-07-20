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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin

    final uiLiabilitiesAsync = ref.watch(uiLiabilityAccountsProvider);

    return uiLiabilitiesAsync.when(
      data: (allAccounts) {
        List<dynamic> displayedAccounts;
        bool isDrilledDown = _drilledDownAccountName != null;

        if (!isDrilledDown) {
          displayedAccounts = allAccounts;
        } else {
          final parentAccount = allAccounts
              .firstWhereOrNull((acc) => acc.name == _drilledDownAccountName);

          if (parentAccount != null &&
              parentAccount.children != null &&
              parentAccount.children!.isNotEmpty) {
            displayedAccounts = parentAccount.children!;
          } else {
            displayedAccounts = allAccounts;
            _drilledDownAccountName = null;
            isDrilledDown = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _drilledDownAccountName = null;
                });
              }
            });
          }
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildTotalLiabilitiesSection(context, ref),
                    const SizedBox(height: 16),
                    _buildLiabilitiesDistributionTitle(),
                    const SizedBox(height: 12),
                    _buildTreemapContainer(
                        context, allAccounts, displayedAccounts, isDrilledDown),
                  ],
                ),
              ),
            ),
            _buildAccountList(context, allAccounts),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('加载数据失败: $err'),
      ),
    );
  }

  /// 构建总负债区域
  Widget _buildTotalLiabilitiesSection(BuildContext context, WidgetRef ref) {
    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: 'year', label: '本年'),
    ];
    final selectedDateRange = ref.watch(selectedDateRangeProvider);

    return Container(
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
                  '总负债',
                  style: TextStyle(fontSize: 14),
                ),
                PopoverSelect(
                  items: dateRangeOptions,
                  value: selectedDateRange,
                  onChanged: (value) {
                    ref.read(selectedDateRangeProvider.notifier).state = value;
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer(
              builder: (context, ref, _) {
                final topLiabilitiesAsync =
                    ref.watch(topLiabilityAccountsProvider);
                return topLiabilitiesAsync.when(
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
                );
              },
            ),
          ),
          Consumer(builder: (context, ref, child) {
            final liabilityTrendAsync =
                ref.watch(liabilityTrendProviderByDateRange(null));
            return liabilityTrendAsync.when(
              data: (liabilityData) {
                return LiabilityTrendChart(liabilityData: liabilityData);
              },
              loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator())),
              error: (error, stack) => SizedBox(
                  height: 140, child: Center(child: Text('加载趋势图失败: $error'))),
            );
          }),
        ],
      ),
    );
  }

  /// 构建负债分布标题
  Widget _buildLiabilitiesDistributionTitle() {
    return const Row(
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
    );
  }

  /// 构建包含 Treemap 的容器
  Widget _buildTreemapContainer(BuildContext context, List<Account> allAccounts,
      List<dynamic> displayedAccounts, bool isDrilledDown) {
    return Container(
      height:
          isDrilledDown ? 280 : 240, // Adjust height if back button is shown
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child:
          _buildTreemap(context, allAccounts, displayedAccounts, isDrilledDown),
    );
  }

  /// 构建 Treemap 图表
  Widget _buildTreemap(BuildContext context, List<Account> allAccounts,
      List<dynamic> displayedAccounts, bool isDrilledDown) {
    final double totalValueAtThisLevel = displayedAccounts
        .where((account) => account.amount > 0)
        .fold(0.0, (sum, account) => sum + account.amount);

    var treeMapData =
        displayedAccounts.where((account) => account.amount > 0).map((account) {
      double? percentage;
      if (totalValueAtThisLevel > 0) {
        percentage = (account.amount / totalValueAtThisLevel) * 100;
      }
      return LiabilityTreemapData(
        name: account.name,
        value: account.amount,
        canDrillDown: account.children != null && account.children!.isNotEmpty,
        percentageOfLevel: percentage,
      );
    }).toList();

    if (treeMapData.isEmpty) {
      if (isDrilledDown) {
        return const Center(child: Text('此分类下无子账户数据'));
      } else {
        treeMapData = [
          LiabilityTreemapData(name: '负债示例 1', value: 40, canDrillDown: false),
          LiabilityTreemapData(name: '负债示例 2', value: 30, canDrillDown: false),
          LiabilityTreemapData(name: '负债示例 3', value: 20, canDrillDown: false),
          LiabilityTreemapData(name: '负债示例 4', value: 10, canDrillDown: false),
        ];
      }
    }

    return Column(
      children: [
        if (isDrilledDown)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  label: const Text('返回上一级'),
                  onPressed: () {
                    setState(() {
                      _drilledDownAccountName = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: LiabilityTreemapWidget(
              key: ValueKey('${_drilledDownAccountName ?? '__treemap_root__'}_${displayedAccounts.length}_${displayedAccounts.map((a) => '${a.name}_${a.amount}').join('_')}'),
              title: isDrilledDown ? '负债分布 > $_drilledDownAccountName' : '负债分布',
              dataItems: treeMapData,
              tooltipValueSuffix: ' ¥',
              drilledDownAccountName: _drilledDownAccountName,
              onDrillDownSelected: (accountName) {
                final selectedAccount = displayedAccounts
                    .firstWhereOrNull((acc) => acc.name == accountName);

                if (selectedAccount != null &&
                    selectedAccount.children != null &&
                    selectedAccount.children!.isNotEmpty) {
                  setState(() {
                    _drilledDownAccountName = accountName;
                  });
                }
              },
              onDoubleClick: (accountName) {
                final selectedAccountToNavigate = allAccounts
                    .firstWhereOrNull((acc) => acc.name == accountName);
                if (selectedAccountToNavigate != null) {
                  bool hasChildren =
                      selectedAccountToNavigate.children != null &&
                          selectedAccountToNavigate.children!.isNotEmpty;
                  if (hasChildren) {
                    GoRouter.of(context).pushNamed(
                        'topLiabilitiesAccountDetail',
                        extra: {'accountId': selectedAccountToNavigate.id});
                  } else {
                    GoRouter.of(context).pushNamed('liabilitiesDetail',
                        extra: {'accountId': selectedAccountToNavigate.id});
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建账户列表
  SliverList _buildAccountList(
      BuildContext context, List<Account> allAccounts) {
    final double totalTopLevelAmount =
        allAccounts.fold(0.0, (sum, account) => sum + account.amount.abs());

    final List<Account> accountsWithPercentage = allAccounts.map((account) {
      double percentage = totalTopLevelAmount == 0
          ? 0.0
          : (account.amount.abs() / totalTopLevelAmount) * 100;
      return Account(
        id: account.id,
        name: account.name,
        amount: account.amount,
        type: account.type,
        icon: account.icon,
        children: account.children,
        currencySymbol: account.currencySymbol,
        percentage: percentage,
      );
    }).toList();

    return SliverList.builder(
      itemCount: accountsWithPercentage.length,
      itemBuilder: (context, index) {
        final account = accountsWithPercentage[index];
        return Padding(
          padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: index == accountsWithPercentage.length - 1 ? 16 : 0),
          child: AccountItem(
            account: account,
            onTap: (tappedAccount) {
              bool hasChildren = tappedAccount.children != null &&
                  tappedAccount.children!.isNotEmpty;
              if (hasChildren) {
                GoRouter.of(context).pushNamed('topLiabilitiesAccountDetail',
                    extra: {'accountId': tappedAccount.id});
              } else {
                GoRouter.of(context).pushNamed('liabilitiesDetail',
                    extra: {'accountId': tappedAccount.id});
              }
            },
          ),
        );
      },
    );
  }
}
