import 'dart:developer' as dev;

class Logger {
  Logger._();

  static void d(String message, {String tag = 'ChatRizz'}) {
    dev.log('[DEBUG] [$tag] $message');
  }

  static void e(String message, {String tag = 'ChatRizz', Object? error, StackTrace? stackTrace}) {
    dev.log('[ERROR] [$tag] $message', error: error, stackTrace: stackTrace);
  }

  static void i(String message, {String tag = 'ChatRizz'}) {
    dev.log('[INFO] [$tag] $message');
  }

  static void w(String message, {String tag = 'ChatRizz'}) {
    dev.log('[WARN] [$tag] $message');
  }
}
