import 'package:flutter/material.dart';
import 'package:flowm/components/common/bottom_input_toolbar.dart';
import 'package:flowm/components/common/number_keypad.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with SingleTickerProviderStateMixin {
  String amount = "0.00";
  late TabController _tabController;
  final List<String> _tabs = ['支出', '收入', '转账', '高级'];
  final TextEditingController _noteController = TextEditingController();
  String _currentDate = DateTime.now().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleDateTap() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _currentDate = selectedDate.toString().split(' ')[0];
        });
      }
    });
  }

  void onKeypadPressed(String value) {
    setState(() {
      if (value == '⌫') {
        if (amount.isNotEmpty) {
          amount = amount.substring(0, amount.length - 1);
          if (amount.isEmpty) {
            amount = "0.00";
          }
        }
      } else if (value == '保存') {
        // TODO: 处理保存逻辑
        Navigator.of(context).pop();
      } else if (value == '.') {
        if (!amount.contains('.')) {
          amount = amount + value;
        }
      } else {
        if (amount == "0.00") {
          amount = value;
        } else {
          amount = amount + value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.green,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
            const Spacer(),
            BottomInputToolbar(
              date: _currentDate,
              noteController: _noteController,
              onDateTap: _handleDateTap,
            ),
            NumberKeypad(
              onKeyPressed: onKeypadPressed,
            ),
          ],
        ),
      ),
    );
  }
}
