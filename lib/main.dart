import 'package:flutter/material.dart';
import 'package:pulse/app.dart';
import 'package:pulse/services/capsule_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await CapsuleDatabase.init();

  runApp(const MyApp());
}
