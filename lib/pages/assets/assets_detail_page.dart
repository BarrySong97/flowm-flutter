import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:intl/intl.dart';

class AssetsDetailPage extends ConsumerStatefulWidget {
  final Account account;
  const AssetsDetailPage({super.key, required this.account});

  @override
  ConsumerState<AssetsDetailPage> createState() => _AssetsDetailPageState();
}

class _AssetsDetailPageState extends ConsumerState<AssetsDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  TimeRange _selectedTimeRange = TimeRange.thisMonth;
  String _selectedFlow = 'in'; // 添加流向控制变量：'in' 或 'out'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > (200 - kToolbarHeight);
    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  void _onTimeRangeChanged(TimeRange timeRange) {
    // 处理时间范围变化的逻辑
    print('Time range changed to: ${timeRange.label}');
    // 在这里可以添加更多逻辑，比如刷新数据、更新图表等
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 400,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Create a boolean to determine if the SliverAppBar is collapsed
                  return Stack(
                    children: [
                      // 白色背景
                      Container(
                        color: Colors.white,
                      ),
                      // Flexible space content
                      FlexibleSpaceBar(
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Consumer(builder: (context, ref, child) {
                              final assetTrendAsync = ref.watch(
                                  assetTrendProviderByTimeRange((
                                accountId: widget.account.id,
                                timeRange: _selectedTimeRange
                              )));

                              final amountToShow = assetTrendAsync.when(
                                data: (assetData) => assetData.isEmpty
                                    ? widget.account.amount
                                    : assetData.last.totalAssets,
                                loading: () => widget.account.amount,
                                error: (e, s) => widget.account.amount,
                              );

                              return Column(
                                spacing: 16,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Placeholder for app bar height
                                  const SizedBox(height: kToolbarHeight),

                                  // VanEck title that shows only when expanded
                                  AnimatedOpacity(
                                    opacity: _isCollapsed ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 250),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        children: [
                                          Text(
                                            widget.account.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Balance amount
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      '${widget.account.currencySymbol}${amountToShow.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  // Chart area
                                  Expanded(
                                    child: AnimatedOpacity(
                                      opacity: _isCollapsed ? 0.0 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      child: Container(
                                        child: assetTrendAsync.when(
                                          data: (assetData) {
                                            if (assetData.isEmpty) {
                                              return const Center(
                                                  child: Text('暂无该时间段资产趋势数据'));
                                            }
                                            return AssetTrendChart(
                                                assetData: assetData);
                                          },
                                          loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          error: (error, stack) => Center(
                                              child: Text('加载趋势图失败: $error')),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),
                                  // Time range selector
                                  AnimatedOpacity(
                                    opacity: _isCollapsed ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 250),
                                    child: TimeRangeSelector(
                                      value: _selectedTimeRange,
                                      onChanged: (TimeRange timeRange) {
                                        setState(() {
                                          _selectedTimeRange = timeRange;
                                        });
                                        _onTimeRangeChanged(timeRange);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 22, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.black87, size: 22),
                  onPressed: () {},
                ),
              ],
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.account.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 移除粘性时间范围选择器
          ];
        },
        body: AssetsDetailBody(
          account: widget.account,
          selectedFlow: _selectedFlow,
          selectedTimeRange: _selectedTimeRange,
          onFlowChanged: (flow) {
            setState(() {
              _selectedFlow = flow;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// 独立的页面主体内容 Widget
class AssetsDetailBody extends StatelessWidget {
  final Account account;
  final String selectedFlow;
  final TimeRange selectedTimeRange;
  final Function(String) onFlowChanged;

  const AssetsDetailBody({
    Key? key,
    required this.account,
    required this.selectedFlow,
    required this.selectedTimeRange,
    required this.onFlowChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F6FB),
      ),
      child: SingleChildScrollView(
        child: Column(
          spacing: 16,
          children: [
            // 流向选择Tab
            _buildFlowSelector(context),

            // Sankey 图表
            _buildSankeyChart(),

            // 交易列表
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowSelector(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFlowTab(context, '资金流入', 'in'),
          ),
          Expanded(
            child: _buildFlowTab(context, '资金流出', 'out'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTab(BuildContext context, String label, String flow) {
    final isSelected = selectedFlow == flow;
    return GestureDetector(
      onTap: () {
        onFlowChanged(flow);
      },
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSankeyChart() {
    return SankeyChartWidget(
      account: account,
      selectedFlow: selectedFlow,
      selectedTimeRange: selectedTimeRange,
    );
  }

  Widget _buildTransactionList() {
    return AccountTransactionList(
      account: account,
      selectedTimeRange: selectedTimeRange,
    );
  }
}

// 独立的 Sankey 图表 Widget
class SankeyChartWidget extends ConsumerWidget {
  final Account account;
  final String selectedFlow;
  final TimeRange selectedTimeRange;

  const SankeyChartWidget({
    required this.account,
    required this.selectedFlow,
    required this.selectedTimeRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sankeyChartDataAsync = ref.watch(assetsSankeyChartDataProvider((
      accountId: account.id,
      flow: selectedFlow,
      timeRange: selectedTimeRange,
      limit: 50,
    )));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  selectedFlow == 'in' ? '资金流入分析' : '资金流出分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: SizedBox(
                key: ValueKey(selectedFlow),
                child: sankeyChartDataAsync.when(
                  data: (sankeyData) {
                    if (sankeyData.nodes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '暂无数据',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '该时间段内没有${selectedFlow == 'in' ? '流入' : '流出'}记录',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 动态计算sankey图表的尺寸
                    final containerWidth =
                        MediaQuery.of(context).size.width; // 减去左右padding
                    final availableWidth = containerWidth - 64; // 减去容器内部padding

                    // 根据nodes数量计算高度
                    final nodeCount = sankeyData.nodes.length;
                    final linkCount = sankeyData.links.length;

                    // 基础高度：每个node至少需要40像素高度，最小200，最大800
                    double calculatedHeight = (nodeCount * 40).toDouble();
                    calculatedHeight = calculatedHeight.clamp(200.0, 900.0);

                    // 如果links很多，适当增加高度
                    if (linkCount > 10) {
                      calculatedHeight += (linkCount - 10) * 20;
                      calculatedHeight = calculatedHeight.clamp(200.0, 900.0);
                    }

                    // 宽度使用容器可用宽度的90%，最小250，最大400
                    double calculatedWidth = availableWidth;
                    calculatedWidth = calculatedWidth.clamp(250.0, 400.0);

                    // 创建 SankeyDataSet
                    final sankeyDataSet = SankeyDataSet(
                      nodes: sankeyData.nodes,
                      links: sankeyData.links,
                    );

                    // 生成布局
                    final sankey = generateSankeyLayout(
                      width: calculatedWidth,
                      height: calculatedHeight,
                      nodeWidth: 12,
                      nodePadding: nodeCount > 10 ? 15 : 20, // 节点多时减少间距
                    );
                    sankeyDataSet.layout(sankey);

                    return SankeyDiagramWidget(
                      data: sankeyDataSet,
                      nodeColors: generateDefaultNodeColorMap(sankeyData.nodes),
                      selectedNodeId: null,
                      onNodeTap: (nodeId) {
                        print('点击了节点: $nodeId');
                        // 这里可以添加节点点击的处理逻辑
                      },
                      size: Size(calculatedWidth, calculatedHeight),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '加载失败',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$error',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 账户交易列表组件
class AccountTransactionList extends ConsumerWidget {
  final Account account;
  final TimeRange selectedTimeRange;

  const AccountTransactionList({
    Key? key,
    required this.account,
    required this.selectedTimeRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(accountTransactionsProvider((
      accountId: account.id,
      timeRange: selectedTimeRange,
    )));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, bottom: 0),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '相关交易',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '暂无交易记录',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '该时间段内没有相关交易',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }

              // 按日期分组交易
              final groupedTransactions =
                  <DateTime, List<TransactionWithAmount>>{};
              for (var transactionWithAmount in transactions) {
                final transactionDate = DateTime(
                  transactionWithAmount.transaction.transactionDate.year,
                  transactionWithAmount.transaction.transactionDate.month,
                  transactionWithAmount.transaction.transactionDate.day,
                );
                if (groupedTransactions.containsKey(transactionDate)) {
                  groupedTransactions[transactionDate]!
                      .add(transactionWithAmount);
                } else {
                  groupedTransactions[transactionDate] = [
                    transactionWithAmount
                  ];
                }
              }

              // 按日期降序排列
              final sortedDates = groupedTransactions.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: sortedDates.length,
                itemBuilder: (context, dateIndex) {
                  final date = sortedDates[dateIndex];
                  final transactionsOnDate = groupedTransactions[date]!;
                  final formattedDate =
                      DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(date);

                  // 计算当日收支总额
                  double dailyIn = 0.0;
                  double dailyOut = 0.0;

                  for (var twa in transactionsOnDate) {
                    if (twa.nature == TransactionNature.INFLOW) {
                      dailyIn += twa.amount.abs();
                    } else if (twa.nature == TransactionNature.OUTFLOW) {
                      dailyOut += twa.amount.abs();
                    }
                  }

                  final formatter =
                      NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                  final formattedDailyIn = formatter.format(dailyIn);
                  final formattedDailyOut = formatter.format(dailyOut);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 12, bottom: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '出 $formattedDailyOut',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '入 $formattedDailyIn',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: transactionsOnDate.length,
                        itemBuilder: (context, transactionIndex) {
                          final transactionWithAmount =
                              transactionsOnDate[transactionIndex];
                          final transaction = transactionWithAmount.transaction;

                          // 判断是否为支出
                          final bool isExpense = transactionWithAmount.nature ==
                              TransactionNature.OUTFLOW;

                          final formatter = NumberFormat.currency(
                              locale: 'zh_CN', symbol: '¥');
                          final formattedAmount = formatter
                              .format(transactionWithAmount.amount.abs());

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            child: TransactionListItem(
                                title: transaction.description ?? '无描述',
                                fromAccountType: transactionWithAmount
                                    .fromAccount?.accountType,
                                toAccountType: transactionWithAmount
                                    .toAccount?.accountType,
                                transactionId:
                                    transaction.transactionId.toString(),
                                subtitle:
                                    '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}',
                                amount: formattedAmount,
                                type: getTransactionFlowType(
                                  transactionWithAmount
                                          .fromAccount?.accountType ??
                                      AccountType.ASSET,
                                  transactionWithAmount
                                          .toAccount?.accountType ??
                                      AccountType.ASSET,
                                ),
                                statusColor: isExpense
                                    ? const Color(0xFF007AFF) // 蓝色表示支出
                                    : const Color(0xFF34C759), // 绿色表示收入
                                isExpense: isExpense,
                                onDelete: () => {
                                      if (transactionWithAmount
                                                  .fromAccount?.accountType !=
                                              null &&
                                          transactionWithAmount
                                                  .toAccount?.accountType !=
                                              null)
                                        {
                                          invalidateProvidersForTransaction(
                                            ref,
                                            fromAccountType:
                                                transactionWithAmount
                                                        .fromAccount
                                                        ?.accountType ??
                                                    AccountType.ASSET,
                                            toAccountType: transactionWithAmount
                                                    .toAccount?.accountType ??
                                                AccountType.ASSET,
                                          )
                                        }
                                    }),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey.shade400,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$error',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
