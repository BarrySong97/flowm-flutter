import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/common/popover_select.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';

/// 当前选中的日期范围提供者
final selectedDateRangeProvider = StateProvider<String>((ref) => 'month');

/// 支出图表数据提供者
final expenseChartDataProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final dateRange = ref.watch(selectedDateRangeProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 根据选择的日期范围计算开始和结束时间
  final now = DateTime.now();
  DateTime startDate;
  final endDate = now;

  switch (dateRange) {
    case 'month':
      startDate = DateTime(now.year, now.month, 1);
      break;
    case 'year':
      startDate = DateTime(now.year, 1, 1);
      break;
    case '60days':
      startDate = now.subtract(const Duration(days: 60));
      break;
    case '30days':
      startDate = now.subtract(const Duration(days: 30));
      break;
    case '15days':
      startDate = now.subtract(const Duration(days: 15));
      break;
    default:
      startDate = DateTime(now.year, now.month, 1);
  }

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PopoverSelectItem> dateRangeOptions = [
      PopoverSelectItem(value: 'month', label: '本月'),
      PopoverSelectItem(value: 'year', label: '本年'),
      PopoverSelectItem(value: '60days', label: '最近60天'),
      PopoverSelectItem(value: '30days', label: '最近30天'),
      PopoverSelectItem(value: '15days', label: '最近15天'),
      PopoverSelectItem(value: 'custom', label: '自定义'),
    ];

    // Sample data for the pie chart
    final List<Map<String, dynamic>> expenseData = [
      // Adjusted values to be less extreme
      {
        'category': '房租/房贷', // Rent/Mortgage
        'amount': 2500.0,
        'color': Colors.red.shade800,
      },
      {
        'category': '餐饮', // Food
        'amount': 800.0,
        'color': Colors.orange,
      },
      {
        'category': '交通', // Transportation
        'amount': 150.0,
        'color': Colors.green,
      },
      {
        'category': '零食和饮料', // Snacks and Drinks
        'amount': 120.0,
        'color': Colors.pink,
      },
      {
        'category': '购物', // Shopping
        'amount': 300.0,
        'color': Colors.blue,
      },
      {
        'category': '生活用品', // Groceries/Household
        'amount': 200.0,
        'color': Colors.blue.shade300,
      },
      {
        'category': '娱乐', // Entertainment
        'amount': 180.0,
        'color': Colors.purple,
      },
      {
        'category': '水电煤网', // Utilities
        'amount': 220.0,
        'color': Colors.purple.shade300,
      },
      {
        'category': '教育/学习', // Education/Learning
        'amount': 350.0,
        'color': Colors.amber,
      },
      {
        'category': '健康/医疗', // Health/Medical
        'amount': 100.0,
        'color': Colors.indigo,
      },
      {
        'category': '宠物', // Pets
        'amount': 80.0,
        'color': Colors.deepOrange,
      },
      {
        'category': '礼品', // Gifts
        'amount': 50.0,
        'color': Colors.brown,
      },
      {
        'category': '订阅服务', // Subscriptions (e.g. Netflix)
        'amount': 60.0,
        'color': Colors.red.shade400,
      },
    ];

    // Calculate total amount from expenseData for percentage calculation
    final double totalExpenseAmount =
        expenseData.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    // Transform expenseData into a list of StyledAccount objects
    final List<StyledAccount> accountsFromExpenseData =
        expenseData.map((expense) {
      final double amount = expense['amount'] as double;
      final String percentage = totalExpenseAmount > 0
          ? '${(amount / totalExpenseAmount * 100).toStringAsFixed(0)}%'
          : '0%';
      return StyledAccount(
        name: expense['category'] as String,
        rawAmount: amount,
        currencySymbol: '¥', // Using Yen as per previous context for expenses
        iconData: Icons.label_outline, // Generic placeholder icon for expenses
        leadingColor: expense['color'] as Color,
        percentageText: percentage,
      );
    }).toList();

    final chartDataAsync = ref.watch(expenseChartDataProvider);

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        spacing: 12,
        children: [
          Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              // 支出统计
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PopoverSelect(
                          items: dateRangeOptions,
                          value: ref.watch(selectedDateRangeProvider),
                          onChanged: (value) {
                            ref.read(selectedDateRangeProvider.notifier).state =
                                value;
                          },
                        ),
                      ],
                    ),
                  ),
                  chartDataAsync.when(
                    data: (chartData) => barchart.MyBarChart(
                      barColor: Colors.red,
                      chartData: chartData,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('加载失败: $error'),
                    ),
                  ),
                ],
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '支出分布',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          Container(
            // height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                CustomPieChart(expenseData: expenseData),
                Container(
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // Optional: if you want a card-like background for the list
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: StyledAccountList(
                      accounts:
                          accountsFromExpenseData), // Use the transformed expenseData
                ),
              ],
            ),
          ),
          // Add a title for the accounts section
        ],
      ),
    ));
  }
}
