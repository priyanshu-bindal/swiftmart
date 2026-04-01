import 'dart:developer' as developer;

class AppLogger {
  static void log(String message, {String name = 'App'}) {
    developer.log(message, name: name);
  }

  static void info(String message) {
    developer.log('INFO: $message', name: 'AppInfo');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      'ERROR: $message',
      name: 'AppError',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
