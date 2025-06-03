import 'package:flowm/pages/add_page.dart';
import 'package:flowm/pages/home_page.dart';
import 'package:flowm/pages/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/home_page/overview_page.dart';
import 'package:flowm/pages/calendar_page.dart';
import 'package:flowm/pages/flow_page.dart';
import 'package:flowm/pages/settings_page.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';

// Provider for MainScreen's selected tab index
final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(key: PageStorageKey('home_page')),
    CalendarPage(),
    AddPage(),
    FlowPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    ref.read(mainScreenIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(selectedIndex),
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
          selectedIndex: selectedIndex,
          showElevation: false,
          height: 55,
          onItemSelected: (index) => _onItemTapped(index),
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
