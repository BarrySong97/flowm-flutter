import 'package:flutter/material.dart';
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
  // 页面控制器
  late final PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 初始化页面控制器
    _pageController = PageController(
      initialPage: ref.read(currentPageIndexProvider),
    );

    // 初始化页面构建函数列表
    _pageBuilders = [
      () => OverviewPage(onPageTap: _onPageTap),
      () => const AssetsPage(),
      () => const ExpensesPage(),
      () => const IncomePage(),
      () => const LiabilitiesPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageTap(int index) {
    // 获取当前页面索引
    final currentIndex = ref.read(currentPageIndexProvider);

    // 如果是相邻页面切换，使用animateToPage进行平滑切换
    if ((index - currentIndex).abs() == 1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 如果是跨页切换，直接跳转到目标页面
      _pageController.jumpToPage(index);
    }

    // 更新当前页面索引
    ref.read(currentPageIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentIndex = ref.watch(currentPageIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          PageHeader(
            currentIndex: currentIndex,
            onTap: _onPageTap,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              itemCount: _pageBuilders.length,
              itemBuilder: (context, index) {
                return LazyPageWidget(
                  builder: _pageBuilders[index],
                  index: index,
                  controller: _pageController,
                );
              },
              onPageChanged: (index) {
                // 只在页面真实改变时更新索引
                if (index != ref.read(currentPageIndexProvider)) {
                  ref.read(currentPageIndexProvider.notifier).state = index;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
