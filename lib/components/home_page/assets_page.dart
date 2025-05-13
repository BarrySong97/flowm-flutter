import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/area_chart.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/chart/treemap.dart';
import 'package:flowm/components/account/account_item.dart'; // Import AccountItem and Account model
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/db/dao/account_dao.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用topAssetAccountsProvider代替直接调用repository
    final topAssetsAsync = ref.watch(topAssetAccountsProvider);
    // 使用uiAccountsProvider获取UI格式的账户数据
    final uiAccountsAsync = ref.watch(uiAccountsProvider);

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
                    child: Text(
                      '总资产',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
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
                  AssetTrendChart()
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
}
