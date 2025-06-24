import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/components/chart/liability_trend_chart.dart';
import 'package:flowm/state/liabilities/liabilities_repository.dart';
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:intl/intl.dart';

class LiabilitiesDetailPage extends ConsumerStatefulWidget {
  final Account account;
  const LiabilitiesDetailPage({Key? key, required this.account})
      : super(key: key);

  @override
  ConsumerState<LiabilitiesDetailPage> createState() =>
      _LiabilitiesDetailPageState();
}

class _LiabilitiesDetailPageState extends ConsumerState<LiabilitiesDetailPage>
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
                            child: Column(
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Placeholder for app bar height
                                SizedBox(height: kToolbarHeight),

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
                                          style: TextStyle(
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
                                    '${widget.account.currencySymbol}${widget.account.amount}',
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
                                    duration: const Duration(milliseconds: 250),
                                    child: Container(
                                      child: Consumer(
                                          builder: (context, ref, child) {
                                        final liabilityTrendAsync = ref.watch(
                                            liabilityTrendProviderByTimeRange((
                                          accountId: widget.account.id,
                                          timeRange: _selectedTimeRange
                                        )));
                                        return liabilityTrendAsync.when(
                                          data: (liabilityData) {
                                            if (liabilityData.isEmpty) {
                                              return const Center(
                                                  child: Text('暂无该时间段负债趋势数据'));
                                            }
                                            return LiabilityTrendChart(
                                                liabilityData: liabilityData);
                                          },
                                          loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          error: (error, stack) => Center(
                                              child: Text('加载趋势图失败: $error')),
                                        );
                                      }),
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

  Widget _buildTabSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Animated selection indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _tabController.index *
                (MediaQuery.of(context).size.width - 32) /
                3,
            top: 0,
            bottom: 0,
            width: (MediaQuery.of(context).size.width - 32) / 3,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Tab buttons
          Row(
            children: [
              Expanded(child: _buildTabButton('Profit & Loss', 0)),
              Expanded(child: _buildTabButton('Balance', 1)),
              Expanded(child: _buildTabButton('Token Balance', 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _tabController.index == index ? Colors.black87 : Colors.grey,
            fontWeight: _tabController.index == index
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
          spacing: 12,
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
      key:
          ValueKey('sankey_${account.id}_${selectedFlow}_${selectedTimeRange}'),
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
class SankeyChartWidget extends ConsumerStatefulWidget {
  final Account account;
  final String selectedFlow;
  final TimeRange selectedTimeRange;

  const SankeyChartWidget({
    Key? key,
    required this.account,
    required this.selectedFlow,
    required this.selectedTimeRange,
  }) : super(key: key);

  @override
  ConsumerState<SankeyChartWidget> createState() => _SankeyChartWidgetState();
}

class _SankeyChartWidgetState extends ConsumerState<SankeyChartWidget>
    with AutomaticKeepAliveClientMixin {
  Future<SankeyChartData>? _futureData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(SankeyChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当关键参数发生变化时才重新加载数据
    if (oldWidget.account.id != widget.account.id ||
        oldWidget.selectedFlow != widget.selectedFlow ||
        oldWidget.selectedTimeRange != widget.selectedTimeRange) {
      _loadData();
    }
  }

  void _loadData() {
    final liabilitiesRepository = ref.read(liabilitiesRepositoryProvider);
    _futureData = liabilitiesRepository.getAccountFlowForSankey(
      accountId: widget.account.id,
      flow: widget.selectedFlow,
      limit: 50,
      startDate: _getStartDateFromTimeRange(widget.selectedTimeRange),
      endDate: _getEndDateFromTimeRange(widget.selectedTimeRange),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以启用 AutomaticKeepAliveClientMixin

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
                  widget.selectedFlow == 'in' ? '资金流入分析' : '资金流出分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            FutureBuilder<SankeyChartData>(
              future: _futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
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
                          '${snapshot.error}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.nodes.isEmpty) {
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
                          '该时间段内没有${widget.selectedFlow == 'in' ? '流入' : '流出'}记录',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sankeyData = snapshot.data!;

                // 创建 SankeyDataSet
                final sankeyDataSet = SankeyDataSet(
                  nodes: sankeyData.nodes,
                  links: sankeyData.links,
                );

                // 生成布局
                final sankey = generateSankeyLayout(
                  width: 350,
                  height: 200,
                  nodeWidth: 12,
                  nodePadding: 20,
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
                  size: Size(350, 200),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getStartDateFromTimeRange(TimeRange timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case TimeRange.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TimeRange.this3Months:
        return now.subtract(Duration(days: 60));
      case TimeRange.this90Days:
        return now.subtract(Duration(days: 90));
      case TimeRange.thisYear:
        return DateTime(now.year, 1, 1);
      case TimeRange.all:
        return DateTime(now.year - 10, 1, 1); // 默认返回10年前
      default:
        return now.subtract(Duration(days: 30));
    }
  }

  DateTime _getEndDateFromTimeRange(TimeRange timeRange) {
    return DateTime.now();
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
    final transactionsAsync = ref.watch(liabilitiesAccountTransactionsProvider((
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
                                fromAccountType: transactionWithAmount
                                    .fromAccount?.accountType,
                                toAccountType: transactionWithAmount
                                    .toAccount?.accountType,
                                transactionId:
                                    transaction.transactionId.toString(),
                                title: transaction.description ?? '无描述',
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
