import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/components/account/account_item.dart';

class AssetItem {
  final int id;
  final String name;
  final double amountNumber;
  final String symbol;
  final String amount;
  final double changePercentage;
  final Color backgroundColor;
  final String percent;

  const AssetItem({
    required this.id,
    required this.name,
    required this.amountNumber,
    required this.symbol,
    required this.amount,
    required this.changePercentage,
    required this.backgroundColor,
    required this.percent,
  });
}

class AssetsOverviewGrid extends ConsumerStatefulWidget {
  final List<AssetItem> assets;
  final String netAssets;
  final String totalAssets;
  final String totalLiabilities;
  final VoidCallback? onViewMoreTap;

  const AssetsOverviewGrid({
    super.key,
    required this.assets,
    required this.netAssets,
    required this.totalAssets,
    required this.totalLiabilities,
    this.onViewMoreTap,
  });

  @override
  ConsumerState<AssetsOverviewGrid> createState() => _AssetsOverviewGridState();
}

class _AssetsOverviewGridState extends ConsumerState<AssetsOverviewGrid> {
  bool _isVisible = true;

  String _maskAmount(String amount) {
    if (_isVisible) return amount;
    return '****';
  }

  Widget _buildOverviewItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _maskAmount(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      '资产概览',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isVisible = !_isVisible;
                        });
                      },
                      child: Icon(
                        _isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    print('查看更多 clicked!'); // Debug log
                    widget.onViewMoreTap?.call(); // Navigate to assets page
                  },
                  child: Row(
                    children: [
                      Text(
                        '查看更多',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            )),

        // Content Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.hardEdge,
          // padding: const EdgeInsets.only(bottom: 0.0),
          child: Column(
            children: [
              // Overview Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverviewItem('净资产', widget.netAssets, Colors.purple),
                    _buildOverviewItem('总资产', widget.totalAssets, Colors.blue),
                    _buildOverviewItem('总负债', widget.totalLiabilities, Colors.orange),
                  ],
                ),
              ),

              // Assets Grid
              GridView.count(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 16.0),
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                childAspectRatio: 2,
                children: widget.assets
                    .map((asset) => _buildAssetCard(asset, context))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(AssetItem asset, BuildContext context) {
    final isPositive = asset.changePercentage >= 0;

    return GestureDetector(
        onTap: () {
          final account = Account(
            id: asset.id,
            name: asset.name,
            amount: asset.amountNumber,
            type: AccountType.ASSET,
            currencySymbol: asset.symbol,
          );
          GoRouter.of(context)
              .pushNamed('assetsDetail', extra: {'accountId': account.id});
        },
        child: Container(
          decoration: BoxDecoration(
            color: asset.backgroundColor,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Text(
                      asset.percent,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _maskAmount(asset.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ));
  }
}
