import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current page index
final currentPageIndexProvider = StateProvider<int>((ref) => 0);

// Provider for the page controller
final pageControllerProvider = Provider<PageController>((ref) {
  final controller =
      PageController(initialPage: ref.watch(currentPageIndexProvider));

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

// Function to navigate to a specific page
void navigateToPage(WidgetRef ref, int index) {
  final controller = ref.read(pageControllerProvider);
  controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
  ref.read(currentPageIndexProvider.notifier).state = index;
}
