import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:flowm/components/calendar/calendar_day.dart';
import 'package:flowm/models/transaction_model.dart' hide Transaction;
import '../../db/app_database.dart';
import '../../db/dao/transaction_dao.dart';
import '../../state/transaction/transaction_repository.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import '../../utils/transaction_type_map.dart';
import '../../utils/transaction_utils.dart';

// Provider to get daily income and expense summary for a specific month
final monthlyCalendarSummaryProvider = StreamProvider.autoDispose
    .family<Map<int, ({double income, double expenses})>, DateTime>(
        (ref, dayForMonth) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);

  final ledgerId = ref.read(selectedLedgerProvider).value?.ledgerId;
  final firstDayOfMonth = DateTime(dayForMonth.year, dayForMonth.month, 1);
  final lastDayOfMonth = (dayForMonth.month < 12)
      ? DateTime(dayForMonth.year, dayForMonth.month + 1, 0, 23, 59, 59)
      : DateTime(dayForMonth.year + 1, 1, 0, 23, 59, 59);

  // Assuming TransactionRepository has an equivalent of watchTransactionsByDay
  // that returns List<TransactionWithAmount> for a date range.
  // Let's call it watchTransactionsWithAmountByDateRange for this example.
  // This method needs to be implemented in TransactionRepository.
  return transactionRepository
      .watchTransactionsWithAmountByDateRange(
          firstDayOfMonth, lastDayOfMonth, ledgerId)
      .map((transactionsWithAmount) {
    final Map<int, ({double income, double expenses})> monthlySummary = {};
    if (transactionsWithAmount.isEmpty) {
      return monthlySummary;
    }

    final Map<int, List<TransactionWithAmount>> transactionsByDay = {};
    for (var ta in transactionsWithAmount) {
      // Assuming TransactionWithAmount has access to the original transaction's date
      // or has its own relevant date property.
      // If TransactionWithAmount wraps a Transaction object, it would be like ta.transaction.transactionDate.day
      // For now, let's assume 'ta.transaction.transactionDate.day' is the correct path.
      // This needs to match the actual structure of TransactionWithAmount.
      final day = ta.transaction.transactionDate.day;
      transactionsByDay.putIfAbsent(day, () => []).add(ta);
    }

    transactionsByDay.forEach((day, dayTransactions) {
      final totals = calculateDailyIncomeAndExpense(dayTransactions);
      if (totals['income']! != 0 || totals['expenses']! != 0) {
        monthlySummary[day] =
            (income: totals['income']!, expenses: totals['expenses']!);
      }
    });
    return monthlySummary;
  });
});

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String customFormatted1 = DateFormat('yyyy年MM月').format(DateTime.now());

  late Stream<List<TransactionWithAmount>> _selectedDayTransactions;
  late final TransactionRepository _transactionRepository;

  @override
  void initState() {
    super.initState();
    _transactionRepository = ref.read(transactionRepositoryProvider);
    _updateSelectedDayTransactions();
  }

  void _updateSelectedDayTransactions() {
    _selectedDayTransactions =
        _transactionRepository.watchTransactionsByDay(_selectedDay);
    if (mounted) {
      setState(() {});
    }
  }

  String _mapNatureToTypeString(TransactionNature nature) {
    switch (nature) {
      case TransactionNature.INFLOW:
        return '收入';
      case TransactionNature.OUTFLOW:
        return '支出';
      case TransactionNature.TRANSFER:
        return '转账';
      case TransactionNature.OTHER:
      default:
        return '其他';
    }
  }

  Color _mapNatureToColor(TransactionNature nature) {
    switch (nature) {
      case TransactionNature.INFLOW:
        return Colors.green;
      case TransactionNature.OUTFLOW:
        return Colors.red;
      case TransactionNature.TRANSFER:
        return Colors.blue;
      case TransactionNature.OTHER:
      default:
        return Colors.grey;
    }
  }

  bool _mapNatureToIsExpense(TransactionNature nature) {
    return nature == TransactionNature.OUTFLOW;
  }

  @override
  Widget build(BuildContext context) {
    final newFormattedHeader = DateFormat('yyyy年MM月').format(_focusedDay);
    if (customFormatted1 != newFormattedHeader) {
      customFormatted1 = newFormattedHeader;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              customFormatted1,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.normal),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDay = DateTime.now();
                  _focusedDay = DateTime.now();
                  _updateSelectedDayTransactions();
                  customFormatted1 =
                      DateFormat('yyyy年MM月').format(DateTime.now());
                });
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '今',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TableCalendar(
              locale: 'zh_CN',
              headerVisible: false,
              daysOfWeekHeight: 40.0,
              rowHeight: 75.0,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Consumer(builder: (context, ref, child) {
                    // Normalize 'day' to the first day of its month to use as a consistent key for the provider
                    final monthKey = DateTime(day.year, day.month, 1);
                    final monthlySummaryAsyncValue =
                        ref.watch(monthlyCalendarSummaryProvider(monthKey));
                    return monthlySummaryAsyncValue.when(
                      data: (summaryMap) {
                        // Get the summary for the specific 'day' from the monthly map
                        final daySummary = summaryMap[day.day];
                        return CalendarDay(
                          day: day,
                          isToday: isSameDay(day, DateTime.now()),
                          isSelected: isSameDay(_selectedDay, day),
                          income: daySummary?.income,
                          expense: daySummary?.expenses,
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: isSameDay(_selectedDay, day),
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: isSameDay(_selectedDay, day),
                      ),
                    );
                  });
                },
                todayBuilder: (context, day, focusedDay) {
                  return Consumer(builder: (context, ref, child) {
                    final monthKey = DateTime(day.year, day.month, 1);
                    final monthlySummaryAsyncValue =
                        ref.watch(monthlyCalendarSummaryProvider(monthKey));
                    return monthlySummaryAsyncValue.when(
                      data: (summaryMap) {
                        final daySummary = summaryMap[day.day];
                        return CalendarDay(
                          day: day,
                          isToday: true,
                          isSelected: isSameDay(_selectedDay, day),
                          income: daySummary?.income,
                          expense: daySummary?.expenses,
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isToday: true,
                        isSelected: isSameDay(_selectedDay, day),
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isToday: true,
                        isSelected: isSameDay(_selectedDay, day),
                      ),
                    );
                  });
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Consumer(builder: (context, ref, child) {
                    final monthKey = DateTime(day.year, day.month, 1);
                    final monthlySummaryAsyncValue =
                        ref.watch(monthlyCalendarSummaryProvider(monthKey));
                    return monthlySummaryAsyncValue.when(
                      data: (summaryMap) {
                        final daySummary = summaryMap[day.day];
                        return CalendarDay(
                          day: day,
                          isSelected: true,
                          isToday: isSameDay(day, DateTime.now()),
                          income: daySummary?.income,
                          expense: daySummary?.expenses,
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isSelected: true,
                        isToday: isSameDay(day, DateTime.now()),
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isSelected: true,
                        isToday: isSameDay(day, DateTime.now()),
                      ),
                    );
                  });
                },
              ),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _updateSelectedDayTransactions();
                    customFormatted1 =
                        DateFormat('yyyy年MM月').format(focusedDay);
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  customFormatted1 = DateFormat('yyyy年MM月').format(focusedDay);
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                holidayTextStyle: TextStyle(color: Colors.red),
                cellMargin: EdgeInsets.only(top: 20.0),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '交易记录',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionWithAmount>>(
              stream: _selectedDayTransactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '错误: ${snapshot.error}\n${snapshot.stackTrace}'));
                }
                final transactionsWithAmount = snapshot.data ?? [];
                if (transactionsWithAmount.isEmpty) {
                  return const Center(child: Text('该日期无交易记录'));
                }
                return SuperListView.builder(
                  itemCount: transactionsWithAmount.length,
                  itemBuilder: (context, index) {
                    final item = transactionsWithAmount[index];
                    final transaction = item.transaction;
                    final amountString =
                        NumberFormat.currency(symbol: '¥', decimalDigits: 2)
                            .format(item.amount.abs());

                    String subtitle =
                        DateFormat('HH:mm').format(transaction.transactionDate);
                    if (item.fromAccount != null && item.toAccount != null) {
                      subtitle =
                          '${item.fromAccount!.accountName} -> ${item.toAccount!.accountName}';
                    } else if (item.nature == TransactionNature.OUTFLOW &&
                        item.toAccount != null) {
                      subtitle = item.toAccount!.accountName;
                    } else if (item.nature == TransactionNature.INFLOW &&
                        item.fromAccount != null) {
                      subtitle = item.fromAccount!.accountName;
                    }

                    return TransactionListItem(
                      title: transaction.description ?? '无描述',
                      subtitle: subtitle,
                      amount: amountString,
                      type: _mapNatureToTypeString(item.nature),
                      statusColor: _mapNatureToColor(item.nature),
                      isExpense: _mapNatureToIsExpense(item.nature),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
