import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/common/period_range_selector.dart';
import 'package:flowm/components/charts/flchart_income_expense_chart.dart';
import 'package:flowm/state/expense/expense_providers.dart' as expense_providers;
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';

// 期间范围选择器状态
final periodRangeProvider = StateProvider<PeriodRange>((ref) => PeriodRange.month);

// 自定义时间范围状态
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// 收支对比数据
class ComparisonData {
  final List<MonthlyComparisonData> monthlyData;
  final PeriodRange periodRange;

  ComparisonData({
    required this.monthlyData,
    required this.periodRange,
  });
}

// 收支对比数据提供者
final comparisonDataProvider = FutureProvider<ComparisonData>((ref) async {
  final periodRange = ref.watch(periodRangeProvider);
  final selectedMonth = ref.watch(expense_providers.selectedMonthProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  final incomeRepository = ref.watch(IncomeRepositoryProvider);
  final selectedLedgerAsync = ref.watch(selectedLedgerProvider);
  
  // 等待获取当前选中的账本
  final selectedLedger = selectedLedgerAsync.when(
    data: (ledger) => ledger,
    loading: () => null,
    error: (_, __) => null,
  );
  
  if (selectedLedger == null) {
    return ComparisonData(monthlyData: [], periodRange: periodRange);
  }
  
  final ledgerId = selectedLedger.ledgerId;
  List<MonthlyComparisonData> monthlyData = [];
  
  switch (periodRange) {
    case PeriodRange.week:
      // 最近7天的数据
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));
      final endDate = now;
      
      // 获取7天的支出和收入数据
      final expenseChartData = await expenseRepository.getExpenseChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );
      
      final incomeChartData = await incomeRepository.getIncomeChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );
      
      // 按日期合并数据
      final Map<String, double> expenseMap = {
        for (var data in expenseChartData) data.day: data.y
      };
      final Map<String, double> incomeMap = {
        for (var data in incomeChartData) data.day: data.y
      };
      
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dayLabel = '${date.month}/${date.day}';
        final expense = expenseMap[dayLabel] ?? 0.0;
        final income = incomeMap[dayLabel] ?? 0.0;
        
        monthlyData.add(MonthlyComparisonData(dayLabel, expense, income));
      }
      break;
      
    case PeriodRange.month:
      // 当前月的每天数据
      final year = selectedMonth.year;
      final month = selectedMonth.month;
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      final expenseChartData = await expenseRepository.getExpenseChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );
      
      final incomeChartData = await incomeRepository.getIncomeChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: ledgerId,
      );
      
      // 按日期合并数据
      final Map<String, double> expenseMap = {
        for (var data in expenseChartData) data.day: data.y
      };
      final Map<String, double> incomeMap = {
        for (var data in incomeChartData) data.day: data.y
      };
      
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final dayLabel = '$month/$day';
        final dayLabelShort = '$day日';
        final expense = expenseMap[dayLabel] ?? 0.0;
        final income = incomeMap[dayLabel] ?? 0.0;
        
        monthlyData.add(MonthlyComparisonData(dayLabelShort, expense, income));
      }
      break;
      
    case PeriodRange.year:
      // 当前年的12个月数据
      final currentYear = selectedMonth.year;
      
      for (int month = 1; month <= 12; month++) {
        final startDate = DateTime(currentYear, month, 1);
        final endDate = DateTime(currentYear, month + 1, 0, 23, 59, 59);
        
        final expenseChartData = await expenseRepository.getExpenseChartData(
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
        );
        
        final incomeChartData = await incomeRepository.getIncomeChartData(
          startDate: startDate,
          endDate: endDate,
          ledgerId: ledgerId,
        );
        
        final monthlyExpense = expenseChartData.fold(0.0, (sum, data) => sum + data.y);
        final monthlyIncome = incomeChartData.fold(0.0, (sum, data) => sum + data.y);
        
        monthlyData.add(MonthlyComparisonData('${month}月', monthlyExpense, monthlyIncome));
      }
      break;
      
    case PeriodRange.range:
      // 自定义时间范围
      if (customRange != null) {
        final startDate = customRange.start;
        final endDate = customRange.end;
        final daysDifference = endDate.difference(startDate).inDays + 1;
        
        if (daysDifference <= 31) {
          // 按天显示
          for (int i = 0; i < daysDifference; i++) {
            final currentDate = startDate.add(Duration(days: i));
            final dayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
            final dayEnd = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);
            
            final expenseChartData = await expenseRepository.getExpenseChartData(
              startDate: dayStart,
              endDate: dayEnd,
              ledgerId: ledgerId,
            );
            
            final incomeChartData = await incomeRepository.getIncomeChartData(
              startDate: dayStart,
              endDate: dayEnd,
              ledgerId: ledgerId,
            );
            
            final dailyExpense = expenseChartData.fold(0.0, (sum, data) => sum + data.y);
            final dailyIncome = incomeChartData.fold(0.0, (sum, data) => sum + data.y);
            
            monthlyData.add(MonthlyComparisonData(
              '${currentDate.month}/${currentDate.day}',
              dailyExpense,
              dailyIncome,
            ));
          }
        } else {
          // 按月显示
          final startMonth = DateTime(startDate.year, startDate.month, 1);
          final endMonth = DateTime(endDate.year, endDate.month + 1, 0);
          
          // 检查是否为完整的年度范围（从1月1日到12月31日）
          final isFullYearRange = startDate.month == 1 && startDate.day == 1 &&
                                  endDate.month == 12 && endDate.day == 31 &&
                                  startDate.year == endDate.year;
          
          DateTime currentMonth = startMonth;
          while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
            final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
            final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0, 23, 59, 59);
            
            // 调整为实际的日期范围
            final actualStart = monthStart.isBefore(startDate) ? startDate : monthStart;
            final actualEnd = monthEnd.isAfter(endDate) ? endDate : monthEnd;
            
            final expenseChartData = await expenseRepository.getExpenseChartData(
              startDate: actualStart,
              endDate: actualEnd,
              ledgerId: ledgerId,
            );
            
            final incomeChartData = await incomeRepository.getIncomeChartData(
              startDate: actualStart,
              endDate: actualEnd,
              ledgerId: ledgerId,
            );
            
            final monthlyExpense = expenseChartData.fold(0.0, (sum, data) => sum + data.y);
            final monthlyIncome = incomeChartData.fold(0.0, (sum, data) => sum + data.y);
            
            // 根据是否为完整年度范围选择标签格式
            final monthLabel = isFullYearRange 
                ? '${currentMonth.month}月'  // 年度视图格式：1月、2月
                : '${currentMonth.year}/${currentMonth.month}';  // 自定义范围格式：2023/1、2023/2
            
            monthlyData.add(MonthlyComparisonData(
              monthLabel,
              monthlyExpense,
              monthlyIncome,
            ));
            
            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
          }
        }
      }
      break;
  }
  
  return ComparisonData(
    monthlyData: monthlyData,
    periodRange: periodRange,
  );
});