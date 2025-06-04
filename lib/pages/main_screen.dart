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

class _MainScreenPage extends StatefulWidget {
  final Widget child;

  const _MainScreenPage({required this.child});

  @override
  State<_MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<_MainScreenPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late final PageController _pageController;
  final List<Widget> _pages = [
    _MainScreenPage(child: HomePage(key: PageStorageKey('home_page'))),
    CalendarPage(),
    AddPage(),
    FlowPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(mainScreenIndexProvider),
      keepPage: false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final currentIndex = ref.read(mainScreenIndexProvider);

    if (index == 0 && currentIndex != 0) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    ref.read(mainScreenIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          if (index != selectedIndex) {
            ref.read(mainScreenIndexProvider.notifier).state = index;
          }
        },
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
          onItemSelected: _onItemTapped,
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
