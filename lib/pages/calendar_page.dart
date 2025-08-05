import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:flowm/components/calendar/calendar_day.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import '../../db/dao/transaction_dao.dart';
import '../../state/transaction/calendar_provider.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import '../../utils/transaction_type_map.dart';
import '../../utils/provider_invalidator.dart';

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
  bool _isTransactionSortAscending = false; // 默认降序（最新在前）

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
        case '支出退款':
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    final selectedLedger =
                        ref.watch(selectedLedgerProvider).value;
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
                          currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: isSameDay(_selectedDay, day),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: isSameDay(_selectedDay, day),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                      ),
                    );
                  });
                },
                todayBuilder: (context, day, focusedDay) {
                  return Consumer(builder: (context, ref, child) {
                    final monthKey = DateTime(day.year, day.month, 1);
                    final monthlySummaryAsyncValue =
                        ref.watch(monthlyCalendarSummaryProvider(monthKey));
                    final selectedLedger =
                        ref.watch(selectedLedgerProvider).value;
                    return monthlySummaryAsyncValue.when(
                      data: (summaryMap) {
                        final daySummary = summaryMap[day.day];
                        return CalendarDay(
                          day: day,
                          isToday: true,
                          isSelected: isSameDay(_selectedDay, day),
                          income: daySummary?.income,
                          expense: daySummary?.expenses,
                          currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isToday: true,
                        isSelected: isSameDay(_selectedDay, day),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isToday: true,
                        isSelected: isSameDay(_selectedDay, day),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                      ),
                    );
                  });
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Consumer(builder: (context, ref, child) {
                    final monthKey = DateTime(day.year, day.month, 1);
                    final monthlySummaryAsyncValue =
                        ref.watch(monthlyCalendarSummaryProvider(monthKey));
                    final selectedLedger =
                        ref.watch(selectedLedgerProvider).value;
                    return monthlySummaryAsyncValue.when(
                      data: (summaryMap) {
                        final daySummary = summaryMap[day.day];
                        return CalendarDay(
                          day: day,
                          isSelected: true,
                          isToday: isSameDay(day, DateTime.now()),
                          income: daySummary?.income,
                          expense: daySummary?.expenses,
                          currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                        );
                      },
                      loading: () => CalendarDay(
                        day: day,
                        isSelected: true,
                        isToday: isSameDay(day, DateTime.now()),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
                      ),
                      error: (err, stack) => CalendarDay(
                        day: day,
                        isSelected: true,
                        isToday: isSameDay(day, DateTime.now()),
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
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
          // 时间日期标题和收支数据
          Consumer(
            builder: (context, ref, child) {
              final monthKey =
                  DateTime(_selectedDay.year, _selectedDay.month, 1);
              final monthlySummaryAsyncValue =
                  ref.watch(monthlyCalendarSummaryProvider(monthKey));
              final selectedLedger = ref.watch(selectedLedgerProvider).value;

              return monthlySummaryAsyncValue.when(
                data: (summaryMap) {
                  final daySummary = summaryMap[_selectedDay.day];
                  final income = daySummary?.income ?? 0.0;
                  final expenses = daySummary?.expenses ?? 0.0;
                  final net = income - expenses;
                  final currencyFormat = NumberFormat.currency(
                      locale: 'zh_CN',
                      symbol: selectedLedger?.currencySymbol ?? '¥');

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy年MM月dd日').format(_selectedDay),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            // 排序按钮
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isTransactionSortAscending =
                                      !_isTransactionSortAscending;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isTransactionSortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isTransactionSortAscending
                                          ? '时间升序'
                                          : '时间降序',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 收支和结余数据
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '收入: ${currencyFormat.format(income)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '支出: ${currencyFormat.format(expenses)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '结余: ${currencyFormat.format(net)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月dd日').format(_selectedDay),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              '加载中...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '收入: ${selectedLedger?.currencySymbol ?? '¥'}0.00',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '支出: ${selectedLedger?.currencySymbol ?? '¥'}0.00',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '结余: ${selectedLedger?.currencySymbol ?? '¥'}0.00',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月dd日').format(_selectedDay),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              '加载失败',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '收入: --',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '支出: --',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '结余: --',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedDayTransactionsAsync =
                    ref.watch(selectedDayTransactionsProvider(_selectedDay));

                return Consumer(builder: (context, ref, child) {
                  final selectedLedger =
                      ref.watch(selectedLedgerProvider).value;
                  final currencyFormat = NumberFormat.currency(
                      locale: 'zh_CN',
                      symbol: selectedLedger?.currencySymbol ?? '¥',
                      decimalDigits: 2);

                  return selectedDayTransactionsAsync.when(
                    data: (transactionsWithAmount) {
                      if (transactionsWithAmount.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '该日期无交易记录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // 对交易进行排序
                      final sortedTransactions =
                          List<TransactionWithAmount>.from(
                              transactionsWithAmount);
                      sortedTransactions.sort((a, b) {
                        if (_isTransactionSortAscending) {
                          return a.transaction.transactionDate
                              .compareTo(b.transaction.transactionDate);
                        } else {
                          return b.transaction.transactionDate
                              .compareTo(a.transaction.transactionDate);
                        }
                      });

                      return SuperListView.builder(
                        itemCount: sortedTransactions.length,
                        itemBuilder: (context, index) {
                          final item = sortedTransactions[index];
                          final transaction = item.transaction;
                          final amountString =
                              currencyFormat.format(item.amount.abs());

                          // 改进时间显示逻辑 - 参考top_expense_detail_page的实现
                          String subtitle = '';
                          final timeStr = DateFormat('HH:mm')
                              .format(transaction.transactionDate);

                          // 优先显示账户信息，时间作为补充
                          if (item.fromAccount != null &&
                              item.toAccount != null) {
                            subtitle =
                                '${item.fromAccount!.accountName} -> ${item.toAccount!.accountName}';
                            // 如果不是00:00，添加时间显示
                            if (timeStr != '00:00') {
                              subtitle += ' · $timeStr';
                            }
                          } else if (item.nature == TransactionNature.OUTFLOW &&
                              item.toAccount != null) {
                            subtitle = item.toAccount!.accountName;
                            if (timeStr != '00:00') {
                              subtitle += ' • $timeStr';
                            }
                          } else if (item.nature == TransactionNature.INFLOW &&
                              item.fromAccount != null) {
                            subtitle = item.fromAccount!.accountName;
                            if (timeStr != '00:00') {
                              subtitle += ' • $timeStr';
                            }
                          } else {
                            // 如果没有账户信息，只显示时间（除非是00:00）
                            subtitle = timeStr != '00:00' ? timeStr : '';
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
                            createDate: transaction.createdAt,
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
                              ref.invalidate(selectedDayTransactionsProvider(
                                  _selectedDay));

                              // 刷新其他相关的providers
                              if (item.fromAccount?.accountType != null &&
                                  item.toAccount?.accountType != null) {
                                invalidateProvidersForTransaction(
                                  ref,
                                  fromAccountType:
                                      item.fromAccount?.accountType,
                                  toAccountType: item.toAccount?.accountType,
                                );
                              }
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
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
