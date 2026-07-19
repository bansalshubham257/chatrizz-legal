import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:chatrizz/core/utils/logger.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> init() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = (details) {
        _crashlytics.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      Logger.e('Crashlytics init error', error: e);
    }
  }

  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> recordError(dynamic error, StackTrace stack) async {
    await _crashlytics.recordError(error, stack);
  }
}
