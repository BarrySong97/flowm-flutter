import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/home_page/overview_page.dart';
import '../components/home_page/assets_page.dart';
import '../components/home_page/expenses_page.dart';
import '../components/home_page/income_page.dart';
import '../components/home_page/liabilities_page.dart';
import '../components/home_page/page_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    OverviewPage(),
    AssetsPage(),
    ExpensesPage(),
    IncomePage(),
    LiabilitiesPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 246, 246, 246),
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: SafeArea(
          child: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 246, 246, 246),
        ),
        child: Column(
          children: [
            PageHeader(
              currentIndex: _currentIndex,
              onTap: _onPageTap,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                children: _pages,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      )),
    );
  }
}
