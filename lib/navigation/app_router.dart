import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:flowm/pages/home_page.dart'; // No longer the initial route
import 'package:flowm/pages/main_screen.dart'; // Import MainScreen
import 'package:flowm/pages/demo_page.dart';

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
    ],
  );
}
