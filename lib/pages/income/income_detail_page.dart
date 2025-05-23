import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:intl/intl.dart'; // For currency formatting

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 收入图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final incomeChartDataProvider =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  print(
      '[incomeChartDataProvider] Fetching chart data with accountId: $accountId');

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId, // 传递 accountId
  );
});

/// 指定账户当月总收入提供者
final accountMonthlyIncomeProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedDate = ref.watch(selectedMonthProvider);
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getAccountIncomeBalance(
    accountId: accountId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// 指定账户累计总收入提供者 (不区分时间)
final accountOverallIncomeProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  return repository.getAccountIncomeTotalBalance(accountId: accountId);
});

class IncomeDetailPage extends ConsumerStatefulWidget {
  final AccountExpenseNode account;

  const IncomeDetailPage({super.key, required this.account});

  @override
  ConsumerState<IncomeDetailPage> createState() => _IncomeDetailPageState();
}

class _IncomeDetailPageState extends ConsumerState<IncomeDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Or Brightness.dark based on AppBar color
      ),
    );
  }

  void _onScroll() {
    final bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset >
            (200 - kToolbarHeight); // 200 is expandedHeight
    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatisticItem(String label, Widget valueWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartDataAsync = ref
        .watch(incomeChartDataProvider(widget.account.accountData.accountId));
    final currentSelectedMonth = ref.watch(selectedMonthProvider);
    final monthlyIncomeAsync = ref.watch(
        accountMonthlyIncomeProvider(widget.account.accountData.accountId));
    final overallIncomeAsync = ref.watch(
        accountOverallIncomeProvider(widget.account.accountData.accountId));
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    Widget buildValueText(double value) {
      return Text(
        currencyFormat.format(value),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    Widget buildLoadingIndicator() {
      return const SizedBox(
        height: 16, // Match text height
        width: 16, // Match text height
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    Widget buildErrorText() {
      return const Text(
        '加载失败',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent, // To show the gradient
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              // 使用不同的绿色渐变
                              Color(0xFF0ba360),
                              Color(0xFF3cba92),
                            ],
                          ),
                        ),
                      ),
                      FlexibleSpaceBar(
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                const SizedBox(
                                    height: kToolbarHeight), // Adjusted padding
                                AnimatedOpacity(
                                  opacity: _isCollapsed ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    widget.account.accountData.accountName,
                                    style: const TextStyle(
                                      fontSize: 24, // Larger when expanded
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 20,
                                  children: [
                                    monthlyIncomeAsync.when(
                                      data: (total) => _buildStatisticItem(
                                          '当月总收入', buildValueText(total)),
                                      loading: () => _buildStatisticItem(
                                          '当月总收入', buildLoadingIndicator()),
                                      error: (err, stack) =>
                                          _buildStatisticItem(
                                              '当月总收入', buildErrorText()),
                                    ),
                                    overallIncomeAsync.when(
                                      data: (total) => _buildStatisticItem(
                                          '累计总收入', buildValueText(total)),
                                      loading: () => _buildStatisticItem(
                                          '累计总收入', buildLoadingIndicator()),
                                      error: (err, stack) =>
                                          _buildStatisticItem(
                                              '累计总收入', buildErrorText()),
                                    ),
                                  ],
                                ),
                                // You can add more info here if needed, like total amount, etc.
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 22, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  widget.account.accountData.accountName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          // Container to apply background color for the body part
          color: const Color(0xFFF5F6FB), // Original Scaffold background
          child: SafeArea(
            top:
                false, // SafeArea for top is handled by SliverAppBar's background
            bottom: true, // Keep bottom SafeArea
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 16.0), // Added top padding
                child: Column(
                  spacing: 12,
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        // 收入统计
                        child: Column(
                          children: [
                            MonthSelectorHeader(
                              initialDate: currentSelectedMonth,
                              onDateChanged: (newDate) {
                                ref.read(selectedMonthProvider.notifier).state =
                                    newDate;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                              child: ColoredBox(color: Colors.transparent),
                            ),
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: chartDataAsync.when(
                                data: (chartData) => barchart.MyBarChart(
                                  barColor: Colors.green,
                                  chartData: chartData,
                                ),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) => Center(
                                  child: Text('加载失败: $error'),
                                ),
                              ),
                            )
                          ],
                        )),

                    // Add a title for the accounts section
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
