import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pulse/app.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          debugPrint('Unhandled error: $error\n$stack');
        }
        return true;
      };

      runApp(const MyApp());
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Zone error: $error\n$stack');
      }
    },
  );
}
