import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pulse/models/models.dart';
import 'package:pulse/app_view.dart';
import 'package:pulse/services/app_lock_service.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/screens/player/audio_player_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'pulse_capsules';
  static const String _channelName = 'Time Capsules';
  static const String _channelDescription =
      'Notifications for time capsule unlocks';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _timeZonesInitialized = false;

  bool _isInitialized = false;
  bool _pluginInitialized = false;
  bool _canScheduleExactAlarms = true;
  String? _pendingCapsuleId;
  bool _isNavigating = false;
  bool _acceptNotificationTaps = false;
  bool _appReadyHandled = false;
  Future<void>? _startupFuture;

  /// Completes notification init and cold-start tap capture. Safe to call
  /// multiple times; runs once.
  Future<void> ensureStartupComplete() {
    return _startupFuture ??= _completeStartup();
  }

  Future<void> _completeStartup() async {
    await initialize();
    unawaited(_runDeferredMaintenance());
  }

  Future<void> _runDeferredMaintenance() async {
    if (!_isInitialized) return;

    try {
      await requestPermissions();
      await rescheduleAllCapsuleNotificationsIfNeeded();
    } catch (e, stack) {
      developer.log(
        'Notification maintenance failed',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static int _notificationId(String capsuleId, {int slot = 0}) {
    final digest = sha256.convert(
      utf8.encode('pulse::notify::$capsuleId::$slot'),
    );
    final bytes = digest.bytes;
    return (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]) &
        0x7FFFFFFF;
  }

  void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    tz.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    _ensureTimeZonesInitialized();

    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      _logFailure('Timezone lookup failed, using UTC', e);
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Converts a device-local [dateTime] to an absolute UTC schedule instant.
  tz.TZDateTime _toScheduledTime(DateTime dateTime) {
    _ensureTimeZonesInitialized();
    return tz.TZDateTime.from(dateTime.toUtc(), tz.UTC);
  }

  Future<bool> _ensureReady() async {
    if (_isInitialized) return true;
    await initialize();
    return _isInitialized;
  }

  void _logFailure(String message, Object error, [StackTrace? stack]) {
    developer.log(
      message,
      name: 'NotificationService',
      error: error,
      stackTrace: stack,
    );
    // ignore: avoid_print
    print('[PULSE] $message: $error');
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _configureLocalTimeZone();

      if (!_pluginInitialized) {
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/launcher_icon',
        );

        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        );
        _pluginInitialized = true;
      }

      try {
        await _createAndroidNotificationChannel();
      } catch (e, stack) {
        _logFailure('Notification channel setup failed', e, stack);
      }

      try {
        _canScheduleExactAlarms = await _checkExactAlarmPermission();
      } catch (_) {
        _canScheduleExactAlarms = false;
      }

      _isInitialized = true;
    } catch (e, stack) {
      _logFailure('NotificationService.initialize failed', e, stack);
      if (_pluginInitialized) {
        _isInitialized = true;
      }
    }
  }

  /// Schedules unlock (+ optional reminder). True when unlock alarm is set.
  Future<bool> scheduleForCapsule(VoiceCapsule capsule) async {
    if (!await _ensureReady()) {
      _logFailure('Notifications not ready', 'initialize returned false');
      return false;
    }

    try {
      await requestPermissions();
    } catch (e, stack) {
      _logFailure('requestPermissions failed', e, stack);
    }

    var unlockScheduled = false;

    try {
      await scheduleCapsuleUnlockNotification(capsule);
      unlockScheduled = true;
    } catch (e, stack) {
      _logFailure('Unlock notification schedule failed', e, stack);
    }

    try {
      await scheduleUnlockReminder(capsule);
    } catch (e, stack) {
      _logFailure('Reminder notification schedule failed', e, stack);
    }

    return unlockScheduled;
  }

  /// Call once when the main UI is ready. Shows home by default; only opens a
  /// capsule on a genuine cold-start notification tap (not hot reload/restart).
  Future<void> onAppReady() async {
    _acceptNotificationTaps = true;
    _pendingCapsuleId = null;

    if (_appReadyHandled) return;
    _appReadyHandled = true;

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return;

    final payload = launchDetails?.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) return;

    // Skip stale launch details replayed after hot reload/restart.
    if (SettingsService.consumedColdStartNotificationPayload == payload) {
      return;
    }

    await SettingsService.setConsumedColdStartNotificationPayload(payload);
    _queueCapsuleNavigation(payload);
  }

  bool _isBlockedByAppLock() =>
      AppLockService.isLockEnabled && AppLockService.isSessionLocked;

  /// Call after the first frame when MaterialApp/navigator is ready
  void processPendingNotificationTap() {
    if (_pendingCapsuleId == null) return;
    if (_isBlockedByAppLock()) return;
    _navigateToCapsule(_pendingCapsuleId!);
  }

  Future<void> _createAndroidNotificationChannel() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return true;

    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    return canSchedule ?? true;
  }

  /// Handle notification tap while app is running or in background.
  void _onNotificationTap(NotificationResponse response) {
    if (!_acceptNotificationTaps) return;

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    unawaited(SettingsService.clearConsumedColdStartNotificationPayload());
    _queueCapsuleNavigation(payload);
  }

  void _queueCapsuleNavigation(String capsuleId) {
    _pendingCapsuleId = capsuleId;

    if (_isBlockedByAppLock()) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingNotificationTap();
      });
      return;
    }

    _navigateToCapsule(capsuleId);
  }

  Future<void> _navigateToCapsule(String capsuleId) async {
    if (_isNavigating) return;

    if (_isBlockedByAppLock()) {
      _pendingCapsuleId = capsuleId;
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCapsule(capsuleId);
      });
      return;
    }

    try {
      final capsule = CapsuleDatabase.getCapsuleById(capsuleId);
      if (capsule == null) {
        debugPrint('Notification tap: capsule not found ($capsuleId)');
        _pendingCapsuleId = null;
        return;
      }

      if (capsule.isLocked) {
        _pendingCapsuleId = null;
        _showLockedCapsuleMessage(capsule);
        return;
      }

      _isNavigating = true;
      _pendingCapsuleId = null;

      navigator.push(
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(capsule: capsule),
        ),
      ).whenComplete(() {
        _isNavigating = false;
      });
    } catch (e, stack) {
      _isNavigating = false;
      _pendingCapsuleId = null;
      debugPrint('Error handling notification tap: $e\n$stack');
    }
  }

  /// Request notification permissions (iOS) and Android runtime permissions
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    bool? androidGranted = true;
    if (androidPlugin != null) {
      final alreadyEnabled = await androidPlugin.areNotificationsEnabled();
      if (alreadyEnabled != true) {
        androidGranted = await androidPlugin.requestNotificationsPermission();
      }
      _canScheduleExactAlarms = await _checkExactAlarmPermission();
      if (!_canScheduleExactAlarms) {
        await androidPlugin.requestExactAlarmsPermission();
        _canScheduleExactAlarms = await _checkExactAlarmPermission();
      }
    }

    bool? iosGranted = true;
    if (iosPlugin != null) {
      iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.UTC);
    if (!scheduledDate.isAfter(now)) {
      throw StateError(
        'Scheduled time $scheduledDate is not after now $now',
      );
    }

    final details = notificationDetails();
    const interpretation =
        UILocalNotificationDateInterpretation.absoluteTime;

    final modes = <AndroidScheduleMode>[
      if (_canScheduleExactAlarms) AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    Object? lastError;
    for (final mode in modes) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation: interpretation,
          payload: payload,
        );
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('zonedSchedule failed: $lastError');
  }

  /// Schedule notification for capsule unlock
  Future<void> scheduleCapsuleUnlockNotification(VoiceCapsule capsule) async {
    if (!await _ensureReady()) return;

    if (capsule.unlockDate.isBefore(DateTime.now())) {
      return;
    }

    final scheduledDate = _toScheduledTime(capsule.unlockDate);

    await _zonedScheduleWithFallback(
      id: _notificationId(capsule.id),
      title: 'Time Capsule Unlocked',
      body: '${capsule.title} is ready to open',
      scheduledDate: scheduledDate,
      payload: capsule.id,
    );
  }

  /// Schedule reminder before unlock (1 day before)
  Future<void> scheduleUnlockReminder(VoiceCapsule capsule) async {
    if (!await _ensureReady()) return;

    final reminderDate = capsule.unlockDate.subtract(const Duration(days: 1));

    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    final scheduledDate = _toScheduledTime(reminderDate);

    await _zonedScheduleWithFallback(
      id: _notificationId(capsule.id, slot: 1),
      title: 'Capsule Unlocking Soon',
      body: '${capsule.title} unlocks tomorrow!',
      scheduledDate: scheduledDate,
      payload: capsule.id,
    );
  }

  /// Cancel notification for a capsule
  Future<void> cancelCapsuleNotification(String capsuleId) async {
    await _notifications.cancel(_notificationId(capsuleId));
    await _notifications.cancel(_notificationId(capsuleId, slot: 1));
  }

  void _showLockedCapsuleMessage(VoiceCapsule capsule) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${capsule.title} is still locked — ${capsule.timeRemainingFormatted}',
        ),
      ),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get notification details with custom styling
  NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap(
          '@mipmap/launcher_icon',
        ),
        color: const Color(0xFF7C73FF),
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final enabled = await androidPlugin.areNotificationsEnabled();
      return enabled ?? false;
    }

    return true;
  }

  /// Reschedule notifications for all locked capsules (e.g. after boot)
  Future<void> rescheduleAllCapsuleNotifications() async {
    if (!_isInitialized) await initialize();

    final lockedCapsules = CapsuleDatabase.getLockedCapsules();
    for (final capsule in lockedCapsules) {
      await scheduleCapsuleUnlockNotification(capsule);
      await scheduleUnlockReminder(capsule);
    }
  }

  /// Only reschedules when pending alarms look incomplete (avoids work every launch).
  Future<void> rescheduleAllCapsuleNotificationsIfNeeded() async {
    if (!_isInitialized) await initialize();

    final lockedCapsules = CapsuleDatabase.getLockedCapsules();
    if (lockedCapsules.isEmpty) return;

    final pending = await getPendingNotifications();
    final expected = lockedCapsules.length * 2;
    if (pending.length >= expected) return;

    await rescheduleAllCapsuleNotifications();
  }
}
