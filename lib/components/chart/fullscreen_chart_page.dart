import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;
import 'package:flowm/components/chart/barchart.dart' as barchart;

enum ChartType { income, expense }

class FullscreenChartPage extends StatefulWidget {
  final List<barchart.ChartData> chartData;
  final int daysInPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final String timeRangeTitle;
  final bool isLineChart;
  final ChartType chartType; // 新增：图表类型参数

  const FullscreenChartPage({
    super.key,
    required this.chartData,
    required this.daysInPeriod,
    required this.timeRangeTitle,
    this.startDate,
    this.endDate,
    this.isLineChart = false,
    this.chartType = ChartType.expense, // 默认为支出（红色）
  });

  @override
  State<FullscreenChartPage> createState() => _FullscreenChartPageState();
}

class _FullscreenChartPageState extends State<FullscreenChartPage> {
  bool _isLineChart = false;
  final ScrollController _scrollController = ScrollController();

  // 获取图表颜色
  Color get chartColor {
    return widget.chartType == ChartType.income ? Colors.green : Colors.red;
  }

  // 获取统计类型文本
  String get statisticTypeText {
    return widget.chartType == ChartType.income ? '收入' : '支出';
  }

  @override
  void initState() {
    super.initState();
    _isLineChart = widget.isLineChart;
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for full screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Auto-scroll to first data point after chart renders
    if (widget.daysInPeriod > 90 && widget.chartData.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstDataPoint();
      });
    }
  }

  void _scrollToFirstDataPoint() {
    if (!_scrollController.hasClients) return;

    // Find the first data point with non-zero value
    int firstDataIndex = widget.chartData.indexWhere((data) => data.y > 0);
    if (firstDataIndex == -1) firstDataIndex = 0;

    // Calculate scroll position (each data point is 12 pixels wide)
    double scrollPosition =
        (firstDataIndex * 12.0) - 100; // Offset to show some context
    if (scrollPosition < 0) scrollPosition = 0;

    // Scroll to the position
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.timeRangeTitle}$statisticTypeText图表',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Chart type toggle
          IconButton(
            onPressed: () {
              setState(() {
                _isLineChart = !_isLineChart;
              });
            },
            icon: Icon(
              _isLineChart ? Icons.bar_chart : Icons.show_chart,
              color: Colors.grey.shade700,
            ),
            tooltip: _isLineChart ? '切换到柱状图' : '切换到折线图',
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.grey.shade700,
            ),
            tooltip: '关闭',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chart header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Title and scroll hint
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${widget.timeRangeTitle}$statisticTypeText统计',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (widget.daysInPeriod > 90) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                '← 左右滑动查看所有数据 →',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    // Right side - Time info and chart mode
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.startDate != null && widget.endDate != null
                              ? '${widget.startDate!.year}/${widget.startDate!.month}/${widget.startDate!.day} - ${widget.endDate!.year}/${widget.endDate!.month}/${widget.endDate!.day}'
                              : '数据范围: ${widget.daysInPeriod}天',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey.shade100,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     _isLineChart ? '折线图模式' : '柱状图模式',
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       color: Colors.grey.shade700,
                        //       fontWeight: FontWeight.w500,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chart content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16,
                      16), // Increased top padding for tooltip space
                  child: widget.daysInPeriod > 90
                      ? SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width:
                                widget.daysInPeriod * 12.0, // 每个数据点12像素宽度，更宽一些
                            child: _isLineChart
                                ? fl_linechart.FlLineChart(
                                    lineColor: chartColor,
                                    chartData: widget.chartData
                                        .map((e) => fl_linechart.ChartData(
                                            e.x, e.y, e.day))
                                        .toList(),
                                    daysInMonth: widget.daysInPeriod,
                                    startDate: widget.startDate,
                                    endDate: widget.endDate,
                                    isLandscape: true,
                                  )
                                : fl_barchart.FlBarChart(
                                    barColor: chartColor,
                                    chartData: widget.chartData
                                        .map((e) => fl_barchart.ChartData(
                                            e.x, e.y, e.day))
                                        .toList(),
                                    daysInMonth: widget.daysInPeriod,
                                    startDate: widget.startDate,
                                    endDate: widget.endDate,
                                    isLandscape: true,
                                  ),
                          ),
                        )
                      : _isLineChart
                          ? fl_linechart.FlLineChart(
                              lineColor: chartColor,
                              chartData: widget.chartData
                                  .map((e) =>
                                      fl_linechart.ChartData(e.x, e.y, e.day))
                                  .toList(),
                              daysInMonth: widget.daysInPeriod,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              isLandscape: true,
                            )
                          : fl_barchart.FlBarChart(
                              barColor: chartColor,
                              chartData: widget.chartData
                                  .map((e) =>
                                      fl_barchart.ChartData(e.x, e.y, e.day))
                                  .toList(),
                              daysInMonth: widget.daysInPeriod,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                              isLandscape: true,
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
