import 'package:flowm/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flowm/components/home_page/overview_page.dart';
import 'package:flowm/pages/calendar_page.dart';
import 'package:flowm/pages/flow_page.dart';
import 'package:flowm/pages/settings_page.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    CalendarPage(),
    CalendarPage(),
    FlowPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: FlashyTabBar(
          selectedIndex: _selectedIndex,
          showElevation: false,
          height: 55,
          onItemSelected: (index) => setState(() {
            _selectedIndex = index;
          }),
          items: [
            FlashyTabBarItem(
              icon: Icon(
                Icons.home,
                size: 24,
              ),
              title: Text('概览'),
            ),
            FlashyTabBarItem(
              icon: Icon(
                Icons.calendar_today,
                size: 24,
              ),
              title: Text('日历'),
            ),
            FlashyTabBarItem(
              icon: Icon(
                Icons.add,
                size: 24,
              ),
              title: Text('添加'),
            ),
            FlashyTabBarItem(
              icon: Icon(
                Icons.swap_horiz,
                size: 24,
              ),
              title: Text('流水'),
            ),
            FlashyTabBarItem(
              icon: Icon(
                Icons.settings,
                size: 24,
              ),
              title: Text('设置'),
            ),
          ],
        ),
      ),
    );
  }
}
