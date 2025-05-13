import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/home_page/overview_page.dart';
import '../components/home_page/assets_page.dart';
import '../components/home_page/expenses_page.dart';
import '../components/home_page/income_page.dart';
import '../components/home_page/liabilities_page.dart';
import '../components/home_page/page_header.dart';
import '../state/home/page_controller_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final List<Widget> _pages = const [
    OverviewPage(),
    AssetsPage(),
    ExpensesPage(),
    IncomePage(),
    LiabilitiesPage(),
  ];

  void _onPageTap(int index) {
    navigateToPage(ref, index);
  }

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(pageControllerProvider);
    final currentIndex = ref.watch(currentPageIndexProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 246, 246, 246),
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: SafeArea(
          child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6FB),
        ),
        child: Column(
          children: [
            PageHeader(
              currentIndex: currentIndex,
              onTap: _onPageTap,
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const ClampingScrollPhysics(),
                children: _pages,
                onPageChanged: (index) {
                  ref.read(currentPageIndexProvider.notifier).state = index;
                },
              ),
            ),
          ],
        ),
      )),
    );
  }
}
