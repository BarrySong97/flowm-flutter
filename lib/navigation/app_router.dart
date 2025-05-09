import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:flowm/pages/home_page.dart'; // No longer the initial route
import 'package:flowm/pages/main_screen.dart'; // Import MainScreen
import 'package:flowm/pages/demo_page.dart';
import 'package:flowm/pages/expense_income_detail_page.dart';

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
          final account = extra?['account'];
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
    ],
  );
}
