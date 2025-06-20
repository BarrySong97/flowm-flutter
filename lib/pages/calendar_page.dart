import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:flowm/components/calendar/calendar_day.dart';
import '../../db/dao/transaction_dao.dart';
import '../../state/transaction/transaction_repository.dart';
import '../../state/transaction/calendar_provider.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import '../../utils/transaction_type_map.dart';

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

  @override
  void initState() {
    super.initState();
  }

  String _getTransactionType(TransactionWithAmount item) {
    // 如果有明确的from和to账户类型，使用getTransactionFlowType
    if (item.fromAccount?.accountType != null &&
        item.toAccount?.accountType != null) {
      return getTransactionFlowType(
          item.fromAccount!.accountType, item.toAccount!.accountType);
    }

    // 回退到基于nature的逻辑
    switch (item.nature) {
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

  Color _getTransactionColor(TransactionWithAmount item) {
    // 如果有明确的from和to账户类型，基于交易类型确定颜色
    if (item.fromAccount?.accountType != null &&
        item.toAccount?.accountType != null) {
      final transactionType = getTransactionFlowType(
          item.fromAccount!.accountType, item.toAccount!.accountType);

      switch (transactionType) {
        case '收入':
          return Colors.green;
        case '支出':
          return Colors.red;
        case '资产转移':
        case '转账':
          return Colors.blue;
        case '偿还债务':
          return Colors.orange;
        case '获得贷款':
          return Colors.purple;
        case '个人投入':
          return Colors.teal;
        case '个人提取':
          return Colors.deepOrange;
        case '费用退款':
          return Colors.lightGreen;
        case '贷款支出':
          return Colors.redAccent;
        default:
          return Colors.grey;
      }
    }

    // 回退到基于nature的逻辑
    switch (item.nature) {
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

  bool _isExpenseTransaction(TransactionWithAmount item) {
    // 如果有明确的from和to账户类型，基于交易类型确定是否为支出
    if (item.fromAccount?.accountType != null &&
        item.toAccount?.accountType != null) {
      final transactionType = getTransactionFlowType(
          item.fromAccount!.accountType, item.toAccount!.accountType);

      return transactionType == '支出' ||
          transactionType == '偿还债务' ||
          transactionType == '个人提取' ||
          transactionType == '贷款支出';
    }

    // 回退到基于nature的逻辑
    return item.nature == TransactionNature.OUTFLOW;
  }

  @override
  Widget build(BuildContext context) {
    final newFormattedHeader = DateFormat('yyyy年MM月').format(_focusedDay);
    if (customFormatted1 != newFormattedHeader) {
      customFormatted1 = newFormattedHeader;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
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
          // 当天收支汇总
          Consumer(
            builder: (context, ref, child) {
              final monthKey =
                  DateTime(_selectedDay.year, _selectedDay.month, 1);
              final monthlySummaryAsyncValue =
                  ref.watch(monthlyCalendarSummaryProvider(monthKey));

              return monthlySummaryAsyncValue.when(
                data: (summaryMap) {
                  final daySummary = summaryMap[_selectedDay.day];
                  final income = daySummary?.income ?? 0.0;
                  final expenses = daySummary?.expenses ?? 0.0;
                  final net = income - expenses;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 0.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 收入
                        Column(
                          children: [
                            Text(
                              '收入',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                      symbol: '¥', decimalDigits: 2)
                                  .format(income),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // 分隔线
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        // 支出
                        Column(
                          children: [
                            Text(
                              '支出',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                      symbol: '¥', decimalDigits: 2)
                                  .format(expenses),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // 分隔线
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        // 净额
                        Column(
                          children: [
                            Text(
                              '净额',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                      symbol: '¥', decimalDigits: 2)
                                  .format(net),
                              style: TextStyle(
                                fontSize: 16,
                                color: net >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('加载中...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedDayTransactionsAsync =
                    ref.watch(selectedDayTransactionsProvider(_selectedDay));

                return selectedDayTransactionsAsync.when(
                  data: (transactionsWithAmount) {
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

                        String subtitle = DateFormat('HH:mm')
                            .format(transaction.transactionDate);
                        if (item.fromAccount != null &&
                            item.toAccount != null) {
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
                          transactionId: transaction.transactionId.toString(),
                          subtitle: subtitle,
                          amount: amountString,
                          type: _getTransactionType(item),
                          statusColor: _getTransactionColor(item),
                          isExpense: _isExpenseTransaction(item),
                          transactionDate: transaction.transactionDate,
                          transactionAmount: item.amount,
                          fullDescription: transaction.description,
                          fromAccountType: item.fromAccount?.accountType,
                          toAccountType: item.toAccount?.accountType,
                          onDelete: () {
                            // 刷新当月数据
                            final monthKey = DateTime(
                                _selectedDay.year, _selectedDay.month, 1);
                            ref.invalidate(
                                monthlyCalendarSummaryProvider(monthKey));

                            // 刷新当天交易列表
                            ref.invalidate(
                                selectedDayTransactionsProvider(_selectedDay));
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text('错误: $error\n$stackTrace'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
