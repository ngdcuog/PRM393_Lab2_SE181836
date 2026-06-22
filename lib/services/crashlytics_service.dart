import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // Catch framework errors automatically
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Catch asynchronous errors outside the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> logHandledException(dynamic error, StackTrace stack, {String? reason}) async {
    await _crashlytics.recordError(error, stack, reason: reason);
  }

  void triggerTestCrash() {
    _crashlytics.crash();
  }
}
