import 'package:flowm/components/account/account_item.dart';
import 'package:flowm/pages/assets_liability_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:flowm/pages/home_page.dart'; // No longer the initial route
import 'package:flowm/pages/main_screen.dart'; // Import MainScreen
import 'package:flowm/pages/demo_page.dart';
import 'package:flowm/pages/expense_income_detail_page.dart';
import 'package:flowm/pages/top_assets_account_detail_page.dart'; // 引入页面

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        // builder: (context, state) => const HomePage(), // Old route
        builder: (context, state) => const MainScreen(), // New route
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => const DemoPage(),
      ),
      GoRoute(
        path: '/account-detail',
        name: 'accountDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final account = extra?['account'] as Account;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ExpenseIncomeDetailPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/assets-liability-detail',
        name: 'assetsLiabilityDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final account = extra?['account'] as Account;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: AssetsLiabilityDetailPage(account: account),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/top-assets-account-detail',
        name: 'topAssetsAccountDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final account = extra?['account']; // 获取account参数
          // TODO: 后续需要将 account 传给 TopAssetsAccountDetailPage
          return CustomTransitionPage<void>(
            key: state.pageKey,
            // child: const TopAssetsAccountDetailPage(), // 修改为传入account

            child: TopAssetsAccountDetailPage(
                account: account as Account), // 传入account
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        },
      ),
    ],
  );
}
