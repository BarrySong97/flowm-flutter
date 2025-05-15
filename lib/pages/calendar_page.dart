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

// Provider to get daily income and expense summary for a specific day
final calendarDaySummaryProvider = StreamProvider.autoDispose
    .family<({double income, double expenses})?, DateTime>((ref, day) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  // Normalize day to ensure time component doesn't affect grouping or fetching
  final normalizedDay = DateTime(day.year, day.month, day.day);

  return transactionRepository
      .watchTransactionsByDay(normalizedDay)
      .map((transactions) {
    if (transactions.isEmpty) {
      return null;
    }
    final totals = calculateDailyIncomeAndExpense(transactions);
    // Only return a summary if there's actual income or expense
    if (totals['income']! == 0 && totals['expenses']! == 0) {
      return null;
    }
    return (income: totals['income']!, expenses: totals['expenses']!);
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
            Container(
              child: const Text(
                '今',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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
                    final summaryAsyncValue =
                        ref.watch(calendarDaySummaryProvider(day));
                    return summaryAsyncValue.when(
                      data: (summary) => CalendarDay(
                        day: day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: isSameDay(_selectedDay, day),
                        income: summary?.income,
                        expense: summary?.expenses,
                      ),
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
                    final summaryAsyncValue =
                        ref.watch(calendarDaySummaryProvider(day));
                    return summaryAsyncValue.when(
                      data: (summary) => CalendarDay(
                        day: day,
                        isToday: true,
                        isSelected: isSameDay(_selectedDay, day),
                        income: summary?.income,
                        expense: summary?.expenses,
                      ),
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
                    final summaryAsyncValue =
                        ref.watch(calendarDaySummaryProvider(day));
                    return summaryAsyncValue.when(
                      data: (summary) => CalendarDay(
                        day: day,
                        isSelected: true,
                        isToday: isSameDay(day, DateTime.now()),
                        income: summary?.income,
                        expense: summary?.expenses,
                      ),
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
