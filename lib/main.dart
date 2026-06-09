import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await CapsuleDatabase.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions
  await notificationService.requestPermissions();

  // Reschedule notifications for existing locked capsules
  await notificationService.rescheduleAllCapsuleNotifications();

  // Capture cold-start notification tap before UI is ready
  await notificationService.handleAppLaunchNotification();

  runApp(const MyApp());
}
