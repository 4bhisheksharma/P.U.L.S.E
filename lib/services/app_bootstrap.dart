import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/utils/hive_storage.dart';

/// Runs all cold-start work while the splash screen is visible.
class AppBootstrap {
  AppBootstrap._();

  static Future<void>? _future;

  /// Safe to call multiple times; runs once per app session.
  static Future<void> run({void Function(String status)? onStatus}) {
    return _future ??= _run(onStatus);
  }

  static void reset() => _future = null;

  static Future<void> _run(void Function(String status)? onStatus) async {
    void status(String message) => onStatus?.call(message);

    status('Preparing storage...');
    try {
      await _openStorage();
    } catch (e, stack) {
      _log('Storage open failed, resetting Hive', e, stack);
      await _openStorage(resetFirst: true);
    }

    status('Setting up services...');
    await _startNotifications();

    status('Almost ready...');
  }

  static Future<void> _openStorage({bool resetFirst = false}) async {
    if (resetFirst) {
      await resetHiveStorage();
    } else {
      await initHiveSafe();
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VoiceCapsuleAdapter());
    }

    await Future.wait([
      CapsuleDatabase.open(),
      SettingsService.open(),
    ]);
  }

  static Future<void> _startNotifications() async {
    try {
      await NotificationService().ensureStartupComplete();
    } catch (e, stack) {
      _log(
        'Notification startup failed — app will continue without alerts',
        e,
        stack,
      );
    }
  }

  static void _log(String message, Object error, StackTrace stack) {
    developer.log(
      message,
      name: 'AppBootstrap',
      error: error,
      stackTrace: stack,
    );
    // Visible in release logcat: adb logcat | findstr PULSE
    // ignore: avoid_print
    print('[PULSE] $message: $error');
  }
}
