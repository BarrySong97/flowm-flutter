import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:intl/intl.dart';

class MonthSelectorHeader extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateChanged;
  final Function()? onLongRangeSelected;

  const MonthSelectorHeader({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    this.onLongRangeSelected,
  });

  @override
  ConsumerState<MonthSelectorHeader> createState() => _MonthSelectorHeaderState();
}

class _MonthSelectorHeaderState extends ConsumerState<MonthSelectorHeader> {
  late DateTime _currentDate;
  late int _selectedYear;
  late int _selectedMonth;
  String _displayType = 'month'; // 'month', '90days', '60days', 'year', 'all'

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
      _displayType = 'month';
      // 更新 Riverpod 状态
      ref.read(selectedTimeRangeTypeProvider.notifier).state = 'month';
      widget.onDateChanged(_currentDate);
    });
  }

  Widget _buildQuickSelectButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
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
          height: 420,
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
                          _displayType = 'month';
                          // 更新 Riverpod 状态
                          ref.read(selectedTimeRangeTypeProvider.notifier).state = 'month';
                          widget.onDateChanged(_currentDate);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Date range options
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快速选择',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickSelectButton('最近90天', () {
                          final date90DaysAgo = DateTime.now().subtract(const Duration(days: 90));
                          setState(() {
                            _currentDate = date90DaysAgo;
                            _selectedYear = date90DaysAgo.year;
                            _selectedMonth = date90DaysAgo.month;
                            _displayType = '90days';
                            // 更新 Riverpod 状态
                            ref.read(selectedTimeRangeTypeProvider.notifier).state = '90days';
                            widget.onDateChanged(date90DaysAgo);
                          });
                          Navigator.pop(context);
                          // 90天以上数据自动全屏
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (widget.onLongRangeSelected != null) {
                              widget.onLongRangeSelected!();
                            }
                          });
                        }),
                        _buildQuickSelectButton('最近60天', () {
                          final date60DaysAgo = DateTime.now().subtract(const Duration(days: 60));
                          setState(() {
                            _currentDate = date60DaysAgo;
                            _selectedYear = date60DaysAgo.year;
                            _selectedMonth = date60DaysAgo.month;
                            _displayType = '60days';
                            // 更新 Riverpod 状态
                            ref.read(selectedTimeRangeTypeProvider.notifier).state = '60days';
                            widget.onDateChanged(date60DaysAgo);
                          });
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickSelectButton('一整年', () {
                          final now = DateTime.now();
                          final yearStart = DateTime(now.year, 1, 1);
                          setState(() {
                            _currentDate = yearStart;
                            _selectedYear = yearStart.year;
                            _selectedMonth = yearStart.month;
                            _displayType = 'year';
                            // 更新 Riverpod 状态
                            ref.read(selectedTimeRangeTypeProvider.notifier).state = 'year';
                            widget.onDateChanged(yearStart);
                          });
                          Navigator.pop(context);
                          // 一整年数据不自动全屏，让用户手动选择
                        }),
                        _buildQuickSelectButton('全部', () {
                          final allTimeStart = DateTime(2020, 1, 1);
                          setState(() {
                            _currentDate = allTimeStart;
                            _selectedYear = allTimeStart.year;
                            _selectedMonth = allTimeStart.month;
                            _displayType = 'all';
                            // 更新 Riverpod 状态
                            ref.read(selectedTimeRangeTypeProvider.notifier).state = 'all';
                            widget.onDateChanged(allTimeStart);
                          });
                          Navigator.pop(context);
                          // 触发全屏模式 - 延迟以确保弹窗完全关闭和状态更新
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (widget.onLongRangeSelected != null) {
                              widget.onLongRangeSelected!();
                            }
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
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

  String _getDisplayText() {
    switch (_displayType) {
      case '90days':
        return '最近90天';
      case '60days':
        return '最近60天';
      case 'year':
        return '${_currentDate.year}年全年';
      case 'all':
        return '全部数据';
      case 'month':
      default:
        final String monthPart = DateFormat('M月', 'zh_CN').format(_currentDate);
        final String yearPart = DateFormat('yyyy年', 'zh_CN').format(_currentDate);
        return '$monthPart$yearPart';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: const Icon(
                  Icons.arrow_back_ios_outlined,
                  size: 16,
                ),
              ),
            ),
            onTap: () => _changeMonth(-1),
          ),
          GestureDetector(
            onTap: () => _showDatePickerBottomSheet(context),
            child: Text(
              _getDisplayText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: const Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 14,
                ),
              ),
            ),
            onTap: () => _changeMonth(1),
          )
        ],
      ),
    );
  }
}
