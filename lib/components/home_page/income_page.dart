import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/components/home_page/widgets/income_statistics_row.dart';
import 'package:flowm/components/home_page/widgets/income_chart_section.dart';
import 'package:flowm/components/home_page/widgets/income_pie_chart_section.dart';
import 'package:flowm/components/home_page/widgets/income_loading_widget.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/config/app_constants.dart';

class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with AutomaticKeepAliveClientMixin {
  // 使用缓存的装饰容器来避免重复创建
  static const EdgeInsets _pagePadding = EdgeInsets.only(
    left: AppConstants.largeSpacing,
    right: AppConstants.largeSpacing,
    bottom: AppConstants.largeSpacing,
  );

  static const BoxDecoration _headerDecoration = BoxDecoration(
    borderRadius:
        BorderRadius.all(Radius.circular(AppConstants.defaultBorderRadius)),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncData = ref.watch(incomePageDataProvider);
    final currentSelectedMonth = ref.watch(selectedMonthProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: _pagePadding,
        child: Column(
          spacing: AppConstants.defaultSpacing,
          children: [
            _IncomeHeader(
              currentSelectedMonth: currentSelectedMonth,
              onDateChanged: (newDate) {
                ref.read(selectedMonthProvider.notifier).state = newDate;
              },
            ),
            asyncData.when(
              data: (data) => _IncomeContent(data: data),
              loading: () => const _OptimizedIncomeLoadingWidget(),
              error: (error, stack) => ErrorDisplayWidget(error: error),
            ),
          ],
        ),
      ),
    );
  }
}

// 将头部组件独立出来，减少不必要的重建
class _IncomeHeader extends StatelessWidget {
  final DateTime currentSelectedMonth;
  final Function(DateTime) onDateChanged;

  const _IncomeHeader({
    required this.currentSelectedMonth,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius:
            BorderRadius.all(Radius.circular(AppConstants.defaultBorderRadius)),
      ),
      child: MonthSelectorHeader(
        initialDate: currentSelectedMonth,
        onDateChanged: onDateChanged,
      ),
    );
  }
}

// 将内容组件独立出来，更好的性能和可维护性
class _IncomeContent extends StatelessWidget {
  final IncomePageData data;

  const _IncomeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppConstants.defaultSpacing,
      children: [
        IncomeStatisticsRow(data: data),
        IncomeChartSection(data: data),
        IncomePieChartSection(data: data),
      ],
    );
  }
}

// 优化的加载组件，提供更好的用户体验
class _OptimizedIncomeLoadingWidget extends StatelessWidget {
  const _OptimizedIncomeLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppConstants.defaultSpacing,
      children: [
        // 统计卡片骨架屏
        Row(
          children: [
            _buildSkeletonCard(),
            const SizedBox(width: AppConstants.smallSpacing),
            _buildSkeletonCard(),
            const SizedBox(width: AppConstants.smallSpacing),
            _buildSkeletonCard(),
          ],
        ),
        // 图表骨架屏
        _buildSkeletonChart(),
        // 饼图和列表骨架屏
        _buildSkeletonPieChartSection(),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Expanded(
      child: Container(
        height: AppConstants.statsCardHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonChart() {
    return Container(
      height: AppConstants.chartHeight,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              '正在加载图表数据...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonPieChartSection() {
    return Container(
      height: AppConstants.pieChartHeight + 200, // 饼图高度 + 列表估计高度
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              '正在加载账户数据...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
