import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';

/// 收入页面专用加载组件
class IncomeLoadingWidget extends StatelessWidget {
  const IncomeLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: AppConstants.loadingHeight,
        child: CircularProgressIndicator(
          strokeWidth: AppConstants.loadingStrokeWidth,
        ),
      ),
    );
  }
}

/// 通用错误显示组件
class ErrorDisplayWidget extends StatelessWidget {
  final Object error;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largeSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
