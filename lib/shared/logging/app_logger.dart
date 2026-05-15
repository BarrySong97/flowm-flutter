import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log('DEBUG', message, error: error, stackTrace: stackTrace, tag: tag);
  }

  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log('INFO', message, error: error, stackTrace: stackTrace, tag: tag);
  }

  static void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log('WARN', message, error: error, stackTrace: stackTrace, tag: tag);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log('ERROR', message, error: error, stackTrace: stackTrace, tag: tag);
  }

  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      message,
      name: tag == null ? 'Flowm.$level' : 'Flowm.$level.$tag',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
