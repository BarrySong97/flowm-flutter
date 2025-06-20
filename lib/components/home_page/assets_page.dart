import 'package:flowm/components/common/popover_select.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model
import 'package:flowm/state/home_page/assets_page_providers.dart';
import 'package:go_router/go_router.dart'; // 引入 GoRouter
import 'package:visibility_detector/visibility_detector.dart'; // 引入 GoRouter

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage>
    with AutomaticKeepAliveClientMixin {
  String? _drilledDownAccountName; // State for current drill-down level
  bool _isDistributionVisible = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            _buildTotalAssetsSection(context, ref),
            _buildAssetDistributionTitle(),
            VisibilityDetector(
              key: const Key('asset-distribution-detector'),
              onVisibilityChanged: (visibilityInfo) {
                if (visibilityInfo.visibleFraction > 0 &&
                    !_isDistributionVisible) {
                  setState(() {
                    _isDistributionVisible = true;
                  });
                }
              },
              child: _buildAssetDistributionSection(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建总资产区域
  Widget _buildTotalAssetsSection(BuildContext context, WidgetRef ref) {
    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: 'year', label: '本年'),
      // PopoverSelectItem(value: 'custom', label: '自定义'),
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
                  '总资产',
                  style: TextStyle(
                    fontSize: 14,
                  ),
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
            child: Consumer(builder: (context, ref, child) {
              final topAssetsAsync = ref.watch(topAssetAccountsProvider);
              return topAssetsAsync.when(
                data: (accounts) {
                  final totalAssets = accounts.fold(
                      0.0, (sum, account) => sum + account.balance);
                  return Text(
                    '¥${totalAssets.toStringAsFixed(2)}',
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
            }),
          ),
          Consumer(builder: (context, ref, child) {
            final assetTrendAsync =
                ref.watch(assetTrendProviderByDateRange(null));
            return assetTrendAsync.when(
              data: (assetData) {
                if (assetData.isEmpty) {
                  return const SizedBox(
                      height: 140, child: Center(child: Text('暂无该时间段资产趋势数据')));
                }
                return AssetTrendChart(assetData: assetData);
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

  /// 构建资产分布内容，包括 Treemap 和账户列表
  Widget _buildAssetDistributionSection(BuildContext context, WidgetRef ref) {
    if (!_isDistributionVisible) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载资产分布...'),
            ],
          ),
        ),
      );
    }

    return Consumer(builder: (context, ref, child) {
      final uiAccountsAsync = ref.watch(uiAccountsProvider);
      return uiAccountsAsync.when(
        data: (allAccounts) {
          if (allAccounts.isEmpty) {
            return const Center(child: Text('暂无资产数据'));
          }

          bool isDrilledDown = _drilledDownAccountName != null;
          List<dynamic> displayedAccounts;

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
              // Fallback if drill-down is invalid
              displayedAccounts = allAccounts;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _drilledDownAccountName = null;
                  });
                }
              });
            }
          }

          return Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTreemapContainer(context, displayedAccounts, isDrilledDown),
              _buildAccountList(context, allAccounts),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('加载数据失败: $err'),
        ),
      );
    });
  }

  /// 构建包含 Treemap 的容器
  Widget _buildTreemapContainer(BuildContext context,
      List<dynamic> displayedAccounts, bool isDrilledDown) {
    return Container(
      height:
          isDrilledDown ? 280 : 240, // Adjust height if back button is shown
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildTreemap(context, displayedAccounts, isDrilledDown),
    );
  }

  /// 构建 Treemap 图表
  Widget _buildTreemap(BuildContext context, List<dynamic> displayedAccounts,
      bool isDrilledDown) {
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
                final selectedAccountToNavigate = displayedAccounts
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
  Widget _buildAccountList(BuildContext context, List<Account> allAccounts) {
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsetsGeometry.only(top: 0),
      itemCount: accountsWithPercentage.length,
      itemBuilder: (context, index) {
        final account = accountsWithPercentage[index];
        return AccountItem(
          account: account,
          onTap: (tappedAccount) {
            bool hasChildren = tappedAccount.children != null &&
                tappedAccount.children!.isNotEmpty;
            if (hasChildren) {
              GoRouter.of(context).pushNamed('topAssetsAccountDetail',
                  extra: {'account': tappedAccount});
            } else {
              GoRouter.of(context)
                  .pushNamed('assetsDetail', extra: {'account': tappedAccount});
            }
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
