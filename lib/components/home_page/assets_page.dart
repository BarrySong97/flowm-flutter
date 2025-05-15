import 'package:flowm/components/common/popover_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/area_chart.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/db/dao/account_dao.dart';

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    // 使用topAssetAccountsProvider代替直接调用repository
    final topAssetsAsync = ref.watch(topAssetAccountsProvider);
    // 使用uiAccountsProvider获取UI格式的账户数据
    final uiAccountsAsync = ref.watch(uiAccountsProvider);

    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: 'year', label: '本年'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: 'custom', label: '自定义'),
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // 总资产区域
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
                          '总资产',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        PopoverSelect(
                          items: dateRangeOptions,
                          defaultValue: 'month', // Default to 'month'
                          onChanged: (value) {
                            // Update the selectedDateRangeProvider when PopoverSelect changes
                            ref.read(selectedDateRangeProvider.notifier).state =
                                value;
                            print('Selected value: $value');
                            // The chart will automatically rebuild as it watches assetTrendProviderByDateRange
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: topAssetsAsync.when(
                      data: (accounts) {
                        final totalAssets = accounts.fold(
                            0.0, (sum, account) => sum + account.balance);
                        return Text(
                          '¥${totalAssets.toStringAsFixed(2)}',
                          style: const TextStyle(
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
                  // Watch the asset trend provider by date range
                  Consumer(builder: (context, ref, child) {
                    // Watch the new provider
                    final assetTrendAsync =
                        ref.watch(assetTrendProviderByDateRange);
                    return assetTrendAsync.when(
                      data: (assetData) {
                        if (assetData.isEmpty) {
                          return const SizedBox(
                              height: 200,
                              child: Center(
                                  child:
                                      Text('暂无该时间段资产趋势数据'))); // Updated message
                        }
                        return AssetTrendChart(assetData: assetData);
                      },
                      loading: () => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator())),
                      error: (error, stack) => SizedBox(
                          height: 200,
                          child: Center(child: Text('加载趋势图失败: $error'))),
                    );
                  }),
                ],
              ),
            ),

            // 资产分布标题
            Row(
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
            ),

            // 资产分布图表
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.hardEdge,
              child: topAssetsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Center(child: Text('暂无资产数据'));
                  }

                  // 将账户数据转换为Treemap数据，过滤掉负值和零值账户
                  final treeMapData = accounts
                      .where((item) => item.balance > 0) // 只保留正余额账户(大于0)
                      .map((item) => TreemapData(
                            name: item.account.accountName,
                            value: item.balance,
                          ))
                      .toList();

                  // 检查是否有数据
                  if (treeMapData.isEmpty) {
                    return Center(child: Text('暂无可显示的资产数据'));
                  }

                  return TreemapWidget(
                    title: '资产分布',
                    dataItems: treeMapData,
                    tooltipValueSuffix: ' ¥',
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('加载数据失败: $err'),
                ),
              ),
            ),

            // 账户列表，使用从数据库获取的UI格式账户数据
            uiAccountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('暂无账户数据'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    return AccountItem(account: accounts[index]);
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
