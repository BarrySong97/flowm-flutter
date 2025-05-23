import 'package:flowm/components/account/account_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart';
import 'package:flowm/components/chart/asset_trend_chart.dart';
import 'package:flowm/components/sankey_chart.dart';
import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/assets/assets_repository.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';

class AssetsDetailPage extends ConsumerStatefulWidget {
  final Account account;
  const AssetsDetailPage({Key? key, required this.account}) : super(key: key);

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
    // Set status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
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
                                        final assetTrendAsync = ref.watch(
                                            assetTrendProviderByTimeRange((
                                          accountId: widget.account.id,
                                          timeRange: _selectedTimeRange
                                        )));
                                        return assetTrendAsync.when(
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
        body: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF5F6FB),
          ),
          child: Column(
            spacing: 12,
            children: [
              // 流向选择Tab
              _buildFlowSelector(),

              // Sankey 图表
              Expanded(
                child: _buildSankeyChart(),
              ),
            ],
          ),
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

  Widget _buildFlowSelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            child: _buildFlowTab('资金流入', 'in'),
          ),
          Expanded(
            child: _buildFlowTab('资金流出', 'out'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTab(String label, String flow) {
    final isSelected = _selectedFlow == flow;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFlow = flow;
        });
      },
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          spacing: 12,
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
                  _selectedFlow == 'in' ? '资金流入分析' : '资金流出分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Consumer(
              builder: (context, ref, child) {
                final assetsRepository = ref.watch(assetsRepositoryProvider);

                return FutureBuilder<SankeyChartData>(
                  future: assetsRepository.getAccountFlowForSankey(
                    accountId: widget.account.id,
                    flow: _selectedFlow,
                    limit: 50,
                    startDate: _getStartDateFromTimeRange(_selectedTimeRange),
                    endDate: _getEndDateFromTimeRange(_selectedTimeRange),
                  ),
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
                              '该时间段内没有${_selectedFlow == 'in' ? '流入' : '流出'}记录',
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

                    // 详细调试信息 - 用于校验金额正确性
                    print('=== Sankey 数据校验 ===');
                    print('目标账户ID: ${widget.account.id}');
                    print('当前流向: $_selectedFlow');
                    print(
                        '时间范围: ${_getStartDateFromTimeRange(_selectedTimeRange)} 到 ${_getEndDateFromTimeRange(_selectedTimeRange)}');

                    print('\n节点信息 (${sankeyData.nodes.length}个):');
                    for (final node in sankeyData.nodes) {
                      print('  节点 ${node.id}: ${node.label}');
                    }

                    print('\n链接信息 (${sankeyData.links.length}个):');
                    double totalFlow = 0;
                    for (final link in sankeyData.links) {
                      print(
                          '  ${link.source.label} → ${link.target.label}: ¥${link.value.toStringAsFixed(2)}');
                      totalFlow += link.value;
                    }

                    print('\n总流量: ¥${totalFlow.toStringAsFixed(2)}');
                    print('================');

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
                      size: Size(350, 250),
                    );
                  },
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
