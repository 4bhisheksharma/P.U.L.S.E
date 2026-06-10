import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only block on data needed before the first frame (lock screen, home list).
  await CapsuleDatabase.init();
  await SettingsService.init();

  runApp(const MyApp());

  // Notifications, permissions, and rescheduling run after the UI is shown.
  unawaited(NotificationService().ensureStartupComplete());
}
