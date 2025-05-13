import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current page index
final currentPageIndexProvider = StateProvider<int>((ref) => 0);

// Provider for the page controller
final pageControllerProvider = Provider<PageController>((ref) {
  // 创建PageController时不依赖于currentPageIndexProvider
  // 这避免了在状态变化时重新创建控制器
  final controller = PageController(initialPage: 0);

  // 监听currentPageIndexProvider的变化
  ref.listen(currentPageIndexProvider, (previous, next) {
    // 只有当页面控制器已连接到视图且索引不同时才执行滑动
    if (controller.hasClients && previous != next) {
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

// Function to navigate to a specific page
void navigateToPage(WidgetRef ref, int index) {
  // 只更新状态提供者，PageController会通过监听器自动响应
  ref.read(currentPageIndexProvider.notifier).state = index;
}
