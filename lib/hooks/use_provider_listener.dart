import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一个自定义 Hook，用于监听一个 Provider 的值，并在其变化时执行一个回调函数。
///
/// [ref] - WidgetRef 实例.
/// [provider] - 要监听的 Provider.
/// [onChange] - 当 Provider 的值变化时要执行的回调函数.
void useProviderListener<T>(
  WidgetRef ref,
  ProviderListenable<T> provider,
  void Function(T? previous, T value) onChange,
) {
  useEffect(() {
    // 使用 ref.listen 监听 provider
    // 当 provider 的值发生变化时，onChange 回调会被调用
    // listen 方法会自动管理订阅的生命周期
    ref.listen<T>(provider, onChange);

    // useEffect 的清理函数返回 null，因为 ref.listen 会自动处理清理
    return null;
  }, [ref, provider, onChange]);
}
