import 'package:flutter/material.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/pages/assets/assets_detail_page.dart';
import 'package:flowm/pages/liabilities/liabilities_detail_page.dart';
import 'package:flowm/pages/expense/expense_detail_page.dart';
import 'package:flowm/pages/income/income_detail_page.dart';
import 'package:flowm/pages/income/top_income_detail_page.dart';
import 'package:flowm/pages/liabilities/top_liabilities_account_detail_page.dart';
import 'package:go_router/go_router.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
// import 'package:flowm/pages/home_page.dart'; // No longer the initial route
import 'package:flowm/pages/main_screen.dart'; // Import MainScreen
import 'package:flowm/pages/splash_page.dart'; // Import SplashPage
import 'package:flowm/pages/expense/top_expense_detail_page.dart';
import 'package:flowm/pages/assets/top_assets_account_detail_page.dart'; // 引入页面
import 'package:flowm/pages/add_page.dart';
import 'package:flowm/pages/version_page.dart';
import 'package:flowm/pages/developer_page.dart';
import 'package:flowm/pages/monthly_details_page.dart';
import 'package:flowm/pages/webdav_config_page.dart';

class AppRouter {
  // 全局导航器键
  static final navigatorKey = GlobalKey<NavigatorState>();
  
  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        // builder: (context, state) => const HomePage(); // Old route
        builder: (context, state) => const MainScreen(), // New route
      ),
      GoRoute(
        path: '/top-expenses-detail',
        name: 'topExpensesDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => TopExpensesDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/top-income-detail',
        name: 'topIncomeDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => TopIncomeDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/expenses-detail',
        name: 'expensesDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => ExpensesDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/income-detail',
        name: 'incomeDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => IncomeDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/assets-detail',
        name: 'assetsDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => AssetsDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/liabilities-detail',
        name: 'liabilitiesDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => LiabilitiesDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/top-assets-account-detail',
        name: 'topAssetsAccountDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => TopAssetsAccountDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/top-liabilities-account-detail',
        name: 'topLiabilitiesAccountDetail',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final accountId = extra?['accountId'] as int?;
          if (accountId == null) {
            throw ArgumentError('Missing required accountId parameter');
          }
          return SwipeablePage(
            builder: (context) => TopLiabilitiesAccountDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/add',
        name: 'add',
        pageBuilder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            final transactionId = extra['transactionId'] as int?;
            final type = extra['type'] as String?;
            return SwipeablePage(
              builder: (context) => AddPage(
                transactionId: transactionId,
                transactionType: type,
              ),
            );
          } else {
            final transactionId = state.extra as int?;
            return SwipeablePage(
              builder: (context) => AddPage(transactionId: transactionId),
            );
          }
        },
      ),
      GoRoute(
        path: '/version',
        name: 'version',
        pageBuilder: (context, state) {
          return SwipeablePage(
            builder: (context) => const VersionPage(),
          );
        },
      ),
      GoRoute(
        path: '/developer',
        name: 'developer',
        pageBuilder: (context, state) {
          return SwipeablePage(
            builder: (context) => const DeveloperPage(),
          );
        },
      ),
      GoRoute(
        path: '/monthly-details',
        name: 'monthlyDetails',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final month = extra?['month'] as String? ?? '未知月份';
          return SwipeablePage(
            builder: (context) => MonthlyDetailsPage(month: month),
          );
        },
      ),
      GoRoute(
        path: '/webdav-config',
        name: 'webdav-config',
        pageBuilder: (context, state) {
          return SwipeablePage(
            builder: (context) => const WebdavConfigPage(),
          );
        },
      ),
    ],
  );
}
