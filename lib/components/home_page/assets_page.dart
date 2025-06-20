import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/components/common/popover_select.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:go_router/go_router.dart'; // 引入 GoRouter

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage>
    with AutomaticKeepAliveClientMixin {
  String? _drilledDownAccountName; // State for current drill-down level

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final asyncAssetsPageData = ref.watch(assetsPageDataProvider);

    return asyncAssetsPageData.when(
      data: (data) {
        if (data.accounts.isEmpty) {
          return const Center(child: Text('暂无资产数据'));
        }

        final totalAssets =
            data.accounts.fold(0.0, (sum, account) => sum + account.amount);

        bool isDrilledDown = _drilledDownAccountName != null;
        List<dynamic> displayedAccounts;

        if (!isDrilledDown) {
          displayedAccounts = data.accounts;
        } else {
          final parentAccount = data.accounts
              .firstWhereOrNull((acc) => acc.name == _drilledDownAccountName);

          if (parentAccount != null &&
              parentAccount.children != null &&
              parentAccount.children!.isNotEmpty) {
            displayedAccounts = parentAccount.children!;
          } else {
            // Fallback if drill-down is invalid
            displayedAccounts = data.accounts;
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
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    _buildTotalAssetsSection(
                        context, ref, totalAssets, data.assetTrend),
                    _buildAssetDistributionTitle(),
                    _buildTreemapContainer(context, data.accounts,
                        displayedAccounts, isDrilledDown),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              sliver: _buildAccountList(context, data.accounts),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('加载数据失败: $err'),
      ),
    );
  }

  /// 构建总资产区域
  Widget _buildTotalAssetsSection(BuildContext context, WidgetRef ref,
      double totalAssets, List<AssetHistoryData> assetTrend) {
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
                const Text('总资产', style: TextStyle(fontSize: 14)),
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
            child: Text(
              '¥${totalAssets.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (assetTrend.isEmpty)
            const SizedBox(
                height: 140, child: Center(child: Text('暂无该时间段资产趋势数据')))
          else
            AssetTrendChart(assetData: assetTrend),
        ],
      ),
    );
  }

  /// 构建资产分布标题
  Widget _buildAssetDistributionTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '资产分布',
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

    final treeMapData =
        displayedAccounts.where((account) => account.amount > 0).map((account) {
      double? percentage;
      if (totalValueAtThisLevel > 0) {
        percentage = (account.amount / totalValueAtThisLevel) * 100;
      }
      return TreemapData(
        name: account.name,
        value: account.amount,
        canDrillDown: account.children != null && account.children!.isNotEmpty,
        percentageOfLevel: percentage,
      );
    }).toList();

    if (treeMapData.isEmpty) {
      return Center(child: Text(isDrilledDown ? '此分类下无子账户数据' : '暂无可显示的资产数据'));
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
            child: TreemapWidget(
              key: ValueKey(_drilledDownAccountName ?? '__treemap_root__'),
              title: isDrilledDown ? '资产分布 > $_drilledDownAccountName' : '资产分布',
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
                // To find the original account object, we must search from the full list
                final selectedAccountToNavigate = allAccounts
                    .firstWhereOrNull((acc) => acc.name == accountName);
                if (selectedAccountToNavigate != null) {
                  bool hasChildren =
                      selectedAccountToNavigate.children != null &&
                          selectedAccountToNavigate.children!.isNotEmpty;
                  if (hasChildren) {
                    GoRouter.of(context).pushNamed('topAssetsAccountDetail',
                        extra: {'account': selectedAccountToNavigate});
                  } else {
                    GoRouter.of(context).pushNamed('assetsDetail',
                        extra: {'account': selectedAccountToNavigate});
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AccountItem(
            account: account,
            onTap: (tappedAccount) {
              bool hasChildren = tappedAccount.children != null &&
                  tappedAccount.children!.isNotEmpty;
              if (hasChildren) {
                GoRouter.of(context).pushNamed('topAssetsAccountDetail',
                    extra: {'account': tappedAccount});
              } else {
                GoRouter.of(context).pushNamed('assetsDetail',
                    extra: {'account': tappedAccount});
              }
            },
          ),
        );
      },
    );
  }
}
