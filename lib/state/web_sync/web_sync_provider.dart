import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/services/web_sync_service.dart';

class WebSyncState {
  final bool isRunning;
  final String? serverUrl;
  final String? error;
  final bool isLoading;

  const WebSyncState({
    this.isRunning = false,
    this.serverUrl,
    this.error,
    this.isLoading = false,
  });

  WebSyncState copyWith({
    bool? isRunning,
    String? serverUrl,
    String? error,
    bool? isLoading,
  }) {
    return WebSyncState(
      isRunning: isRunning ?? this.isRunning,
      serverUrl: serverUrl ?? this.serverUrl,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WebSyncNotifier extends StateNotifier<WebSyncState> {
  WebSyncNotifier() : super(const WebSyncState());

  Future<void> startServer() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = await WebSyncService.startServer();
      if (url != null) {
        state = state.copyWith(
          isRunning: true,
          serverUrl: url,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          error: '启动服务失败',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: '启动服务失败: $e',
        isLoading: false,
      );
    }
  }

  Future<void> stopServer() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await WebSyncService.stopServer();
      state = state.copyWith(
        isRunning: false,
        serverUrl: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: '停止服务失败: $e',
        isLoading: false,
      );
    }
  }

  void updateServerStatus() {
    state = state.copyWith(
      isRunning: WebSyncService.isRunning,
      serverUrl: WebSyncService.serverUrl,
    );
  }
}

final webSyncProvider = StateNotifierProvider<WebSyncNotifier, WebSyncState>(
  (ref) => WebSyncNotifier(),
);
