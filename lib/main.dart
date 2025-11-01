import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await CapsuleDatabase.init();

  // Initialize notification service
  await NotificationService().initialize();

  // Request notification permissions
  await NotificationService().requestPermissions();

  runApp(const MyApp());
}
