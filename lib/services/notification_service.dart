import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pulse/models/models.dart';
import 'package:pulse/app_view.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/screens/player/audio_player_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
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

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) async {
    // Navigate to specific capsule when notification is tapped
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final capsuleId = response.payload!;
        final capsule = CapsuleDatabase.getCapsuleById(capsuleId);

        if (capsule != null && navigatorKey.currentContext != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => AudioPlayerScreen(capsule: capsule),
            ),
          );
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    // Request Android permission (API 33+)
    bool? androidGranted = true;
    if (androidPlugin != null) {
      androidGranted = await androidPlugin.requestNotificationsPermission();
    }

    // Request iOS permissions
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

  /// Schedule notification for capsule unlock
  Future<void> scheduleCapsuleUnlockNotification(VoiceCapsule capsule) async {
    if (!_isInitialized) await initialize();

    // Only schedule if unlock date is in the future
    if (capsule.unlockDate.isBefore(DateTime.now())) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(capsule.unlockDate, tz.local);

    await _notifications.zonedSchedule(
      capsule.id.hashCode, // Use capsule ID hash as notification ID
      '🔓 Time Capsule Unlocked!',
      '${capsule.title} is ready to open',
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: capsule.id,
    );
  }

  /// Schedule reminder before unlock (1 day before)
  Future<void> scheduleUnlockReminder(VoiceCapsule capsule) async {
    if (!_isInitialized) await initialize();

    final reminderDate = capsule.unlockDate.subtract(const Duration(days: 1));

    // Only schedule if reminder date is in the future
    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local);

    await _notifications.zonedSchedule(
      (capsule.id.hashCode + 1), // Different ID for reminder
      '⏰ Capsule Unlocking Soon',
      '${capsule.title} unlocks tomorrow!',
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: capsule.id,
    );
  }

  /// Cancel notification for a capsule
  Future<void> cancelCapsuleNotification(String capsuleId) async {
    await _notifications.cancel(capsuleId.hashCode);
    await _notifications.cancel(capsuleId.hashCode + 1); // Cancel reminder too
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails(),
      payload: payload,
    );
  }

  /// Get notification details with custom styling
  NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'pulse_capsules',
        'Time Capsules',
        channelDescription: 'Notifications for time capsule unlocks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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

    return true; // Assume enabled on other platforms
  }
}
