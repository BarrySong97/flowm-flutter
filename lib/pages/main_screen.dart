import 'package:flowm/pages/add_page.dart';
import 'package:flowm/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/pages/calendar_page.dart';
import 'package:flowm/pages/flow_page.dart';
import 'package:flowm/pages/settings_page.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flowm/utils/snackbar_utils.dart';
import 'package:flowm/state/add_page_params_provider.dart';
import 'package:go_router/go_router.dart';

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
  StreamSubscription? _linkSubscription;
  late AppLinks _appLinks;
  final List<Widget> _pages = [
    _MainScreenPage(child: HomePage(key: PageStorageKey('home_page'))),
    CalendarPage(),
    FlowPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _tabIndexToPageIndex(ref.read(mainScreenIndexProvider)),
      keepPage: false,
    );

    // 初始化app_links深度链接监听
    _initAppLinks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  int _tabIndexToPageIndex(int tabIndex) {
    if (tabIndex > 2) {
      return tabIndex - 1;
    }
    return tabIndex;
  }

  int _pageIndexToTabIndex(int pageIndex) {
    if (pageIndex >= 2) {
      return pageIndex + 1;
    }
    return pageIndex;
  }

  /// 初始化app_links深度链接监听
  void _initAppLinks() async {
    try {
      _appLinks = AppLinks();

      // 监听应用正在运行时的深度链接
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleIncomingLink(uri.toString());
      }, onError: (err) {
        debugPrint('[AppLinks] 深度链接监听错误: $err');
      });

      // 处理应用启动时的初始链接
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink.toString());
      }
    } catch (e) {
      debugPrint('[AppLinks] 初始化失败: $e');
    }
  }

  /// 处理传入的深度链接
  void _handleIncomingLink(String uri) {
    try {
      final Uri parsedUri = Uri.parse(uri);
      debugPrint('[AppLinks] 收到深度链接: $uri');

      // 解析路径和参数
      final String path = parsedUri.path;
      final Map<String, String> queryParams = parsedUri.queryParameters;

      // 根据路径和参数执行相应操作
      _processLinkData(path, queryParams);
    } catch (e) {
      debugPrint('[AppLinks] 解析深度链接失败: $e');
      SnackBarUtils.showError(context, '深度链接格式错误');
    }
  }

  /// 处理链接数据并执行相应操作
  void _processLinkData(String path, Map<String, String> queryParams) {
    // 打印所有参数供调试
    debugPrint('[AppLinks] 路径: $path');
    debugPrint('[AppLinks] 查询参数: $queryParams');

    // 根据路径导航到不同页面
    switch (path) {
      case '/home':
      case '/':
        _navigateToTab(0, queryParams);
        break;
      case '/calendar':
        _navigateToTab(1, queryParams);
        break;
      case '/add':
        _navigateToAddPage(queryParams);
        break;
      case '/flow':
      case '/transactions':
        _navigateToTab(3, queryParams);
        break;
      // case '/settings':
      //   _navigateToTab(4, queryParams);
      //   break;
      default:
        // 如果路径不匹配，显示参数信息
        _showLinkInfo(path, queryParams);
        break;
    }
  }

  void _navigateToAddPage(Map<String, String> queryParams) {
    if (queryParams.isNotEmpty) {
      final params = AddPageParams.fromMap(queryParams);
      ref.read(addPageParamsProvider.notifier).state = params;
      debugPrint('[AppLinks] 设置AddPage参数: $params');
    }
    GoRouter.of(context).push('/add');
  }

  /// 导航到指定标签页并处理参数
  void _navigateToTab(int tabIndex, Map<String, String> queryParams) {
    // 切换到指定标签页, 只更新 provider，让 listener 去驱动页面切换
    ref.read(mainScreenIndexProvider.notifier).state = tabIndex;

    // 如果有参数，显示给用户
    if (queryParams.isNotEmpty) {
      _showParametersInfo(queryParams);
    }
  }

  /// 显示链接信息
  void _showLinkInfo(String path, Map<String, String> queryParams) {
    String message = '收到深度链接\n路径: $path';

    if (queryParams.isNotEmpty) {
      message += '\n参数:';
      queryParams.forEach((key, value) {
        message += '\n$key: $value';
      });
    }

    SnackBarUtils.showInfo(context, message);
  }

  /// 显示参数信息
  void _showParametersInfo(Map<String, String> queryParams) {
    String message = '收到参数:';
    queryParams.forEach((key, value) {
      message += '\n$key: $value';
    });

    SnackBarUtils.showInfo(context, message);
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      context.push('/add');
    } else {
      ref.read(mainScreenIndexProvider.notifier).state = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);

    ref.listen<int>(mainScreenIndexProvider, (previous, next) {
      if (next != 2) {
        final pageIndex = _tabIndexToPageIndex(next);
        if (_pageController.hasClients &&
            pageIndex != _pageController.page?.round()) {
          _pageController.jumpToPage(pageIndex);
        }
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          final tabIndex = _pageIndexToTabIndex(index);
          if (tabIndex != selectedIndex) {
            ref.read(mainScreenIndexProvider.notifier).state = tabIndex;
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
            // FlashyTabBarItem(
            //   icon: Icon(
            //     Icons.settings,
            //     size: 24,
            //   ),
            //   title: Text('设置'),
            // ),
          ],
        ),
      ),
    );
  }
}
