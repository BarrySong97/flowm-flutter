import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelectorHeader extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateChanged;

  const MonthSelectorHeader({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<MonthSelectorHeader> createState() => _MonthSelectorHeaderState();
}

class _MonthSelectorHeaderState extends State<MonthSelectorHeader> {
  late DateTime _currentDate;
  late int _selectedYear;
  late int _selectedMonth;

  // Define a range for years, e.g., 10 years before and after the current year
  final List<int> _years = List<int>.generate(
      21, (index) => DateTime.now().year - 10 + index); // Example range

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _selectedYear = _currentDate.year;
    _selectedMonth = _currentDate.month;
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _currentDate =
          DateTime(_currentDate.year, _currentDate.month + monthOffset, 1);
      _selectedYear = _currentDate.year;
      _selectedMonth = _currentDate.month;
      widget.onDateChanged(_currentDate);
    });
  }

  void _showDatePickerBottomSheet(BuildContext context) {
    int tempSelectedYear = _selectedYear;
    int tempSelectedMonth = _selectedMonth;

    final FixedExtentScrollController yearController =
        FixedExtentScrollController(initialItem: _years.indexOf(_selectedYear));
    final FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: .0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () {
                        setState(() {
                          _currentDate =
                              DateTime(tempSelectedYear, tempSelectedMonth);
                          _selectedYear = tempSelectedYear;
                          _selectedMonth = tempSelectedMonth;
                          widget.onDateChanged(_currentDate);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: yearController,
                        itemExtent: 32.0,
                        onSelectedItemChanged: (int index) {
                          tempSelectedYear = _years[index];
                        },
                        children: _years.map((int year) {
                          return Center(child: Text('$year年'));
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: monthController,
                        itemExtent: 32.0,
                        onSelectedItemChanged: (int index) {
                          tempSelectedMonth = index + 1;
                        },
                        children: List<Widget>.generate(12, (int index) {
                          return Center(child: Text('${index + 1}月'));
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format date as "M月yyyy年" e.g. "7月2024年"
    final String monthPart = DateFormat('M月', 'zh_CN').format(_currentDate);
    final String yearPart = DateFormat('yyyy年', 'zh_CN').format(_currentDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white, // Or your desired background color

        borderRadius:
            BorderRadius.circular(6), // Optional: if you want rounded corners
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF5F6FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: GestureDetector(
                child: const Icon(
                  Icons.arrow_back_ios_outlined,
                  size: 16,
                ),
                onTap: () => _changeMonth(-1),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showDatePickerBottomSheet(context),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Default color for both spans
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: monthPart,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: yearPart,
                    // Default fontWeight will be normal
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF5F6FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: GestureDetector(
                child: const Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 14,
                ),
                onTap: () => _changeMonth(1),
              ),
            ),
          )
        ],
      ),
    );
  }
}
