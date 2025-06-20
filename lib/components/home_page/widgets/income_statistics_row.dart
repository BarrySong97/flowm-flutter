import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../../../utils/number_format_utils.dart';
import '../../../state/icome/income_providers.dart';

/// 收入统计行组件
class IncomeStatisticsRow extends StatelessWidget {
  final IncomePageData data;

  const IncomeStatisticsRow({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatsItem('当月总收入', data.currentMonthTotal),
        const SizedBox(width: AppConstants.smallSpacing),
        _buildStatsItem('当月日均', data.dailyAverage),
        const SizedBox(width: AppConstants.smallSpacing),
        _buildChangeStatsItem(data),
      ],
    );
  }

  Widget _buildStatsItem(String title, double value) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
        height: AppConstants.statsCardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              NumberFormatUtils.formatCurrencyWithSymbol(value),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeStatsItem(IncomePageData data) {
    final isPositive = data.changePercentage > 0;
    final isNegative = data.changePercentage < 0;

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
        height: AppConstants.statsCardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Tooltip(
          message:
              '上月收入: ${NumberFormatUtils.formatCurrencyWithSymbol(data.previousMonthTotal)}',
          child: Column(
            children: [
              const Text(
                '较上月收入',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPositive)
                    const Icon(Icons.arrow_upward,
                        color: Colors.green, size: 16),
                  if (isNegative)
                    const Icon(Icons.arrow_downward,
                        color: Colors.red, size: 16),
                  if (!isPositive && !isNegative) const SizedBox(width: 16),
                  Text(
                    NumberFormatUtils.formatPercentage(data.changePercentage),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? Colors.green
                          : (isNegative ? Colors.red : Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
