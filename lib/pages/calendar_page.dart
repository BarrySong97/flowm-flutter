import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:flowm/components/calendar/calendar_day.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/models/transaction_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String customFormatted1 = DateFormat('yyyy年MM月').format(DateTime.now());
  final List<Transaction> transactions = Transaction.getSampleData();

  @override
  Widget build(BuildContext context) {
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
              rowHeight: 62.0,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return CalendarDay(
                    day: day,
                    isToday: isSameDay(day, DateTime.now()),
                    isSelected: isSameDay(_selectedDay, day),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return CalendarDay(
                    day: day,
                    isToday: true,
                    isSelected: isSameDay(_selectedDay, day),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return CalendarDay(
                    day: day,
                    isSelected: true,
                    isToday: isSameDay(day, DateTime.now()),
                  );
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
                _focusedDay = focusedDay;
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
            child: SuperListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionListItem(
                  title: transaction.title,
                  subtitle: transaction.subtitle,
                  amount: transaction.amount,
                  type: transaction.type,
                  statusColor: transaction.statusColor,
                  isExpense: transaction.isExpense,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
