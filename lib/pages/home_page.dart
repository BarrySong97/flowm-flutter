import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/home_page/overview_page.dart';
import '../components/home_page/assets_page.dart';
import '../components/home_page/expenses_page.dart';
import '../components/home_page/income_page.dart';
import '../components/home_page/liabilities_page.dart';
import '../components/home_page/page_header.dart';
import '../components/common/keep_alive_wrapper.dart';
import '../state/home/page_controller_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin {
  // 页面列表
  late final List<Widget Function()> _pageBuilders;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 初始化页面构建函数列表
    _pageBuilders = [
      () => const OverviewPage(),
      () => const AssetsPage(),
      () => const ExpensesPage(),
      () => const IncomePage(),
      () => const LiabilitiesPage(),
    ];
  }

  void _onPageTap(int index) {
    // 使用自定义导航方法切换页面
    navigateToPage(ref, index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                child: PageView.builder(
                  controller: pageController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _pageBuilders.length,
                  itemBuilder: (context, index) {
                    return LazyPageWidget(
                      builder: _pageBuilders[index],
                      index: index,
                      controller: pageController,
                    );
                  },
                  onPageChanged: (index) {
                    if (index != currentIndex) {
                      ref.read(currentPageIndexProvider.notifier).state = index;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
