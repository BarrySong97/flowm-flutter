import 'package:flutter/material.dart';

class AssetItem {
  final String symbol;
  final String amount;
  final double changePercentage;
  final Color backgroundColor;

  const AssetItem({
    required this.symbol,
    required this.amount,
    required this.changePercentage,
    required this.backgroundColor,
  });
}

class AssetsOverviewGrid extends StatelessWidget {
  final List<AssetItem> assets;
  final String netAssets;
  final String totalAssets;
  final String totalLiabilities;

  const AssetsOverviewGrid({
    super.key,
    required this.assets,
    required this.netAssets,
    required this.totalAssets,
    required this.totalLiabilities,
  });

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
          amount,
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
        const Padding(
            padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '资产概览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '查看更多',
                  style: TextStyle(fontSize: 12),
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
          child: Column(
            children: [
              // Overview Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverviewItem('净资产', netAssets, Colors.purple),
                    _buildOverviewItem('总资产', totalAssets, Colors.blue),
                    _buildOverviewItem('总负债', totalLiabilities, Colors.orange),
                  ],
                ),
              ),

              // Assets Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                childAspectRatio: 2,
                children:
                    assets.map((asset) => _buildAssetCard(asset)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(AssetItem asset) {
    final isPositive = asset.changePercentage >= 0;
    final changeText =
        '${isPositive ? "+" : ""}${asset.changePercentage.toStringAsFixed(2)}%';

    return Container(
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
                asset.symbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Text(
                  changeText,
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
            asset.amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
