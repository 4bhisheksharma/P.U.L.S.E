import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:pulse/theme/my_app_theme.dart';

/// Checks Google Play for in-app updates (Android only).
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  bool _checked = false;
  bool _flexibleReady = false;

  /// Call once after the main UI is visible. No-op on iOS/web/debug sideloads.
  Future<void> checkForUpdate(BuildContext context) async {
    if (_checked || kIsWeb || !Platform.isAndroid) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      final preferImmediate = info.immediateUpdateAllowed &&
          (info.updatePriority >= 4 || !info.flexibleUpdateAllowed);

      if (preferImmediate) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          _flexibleReady = true;
          if (context.mounted) _showFlexibleReadySnackBar(context);
        }
        return;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Unavailable outside Play Store installs (debug APK, emulator, etc.).
    }
  }

  Future<void> completeFlexibleUpdate(BuildContext context) async {
    if (!_flexibleReady) return;

    try {
      await InAppUpdate.completeFlexibleUpdate();
      _flexibleReady = false;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not install the update. Try again later.'),
          backgroundColor: MyAppTheme.errorColor,
        ),
      );
    }
  }

  void _showFlexibleReadySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Restart to install.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'INSTALL',
          textColor: MyAppTheme.primaryColor,
          onPressed: () => completeFlexibleUpdate(context),
        ),
      ),
    );
  }
}
