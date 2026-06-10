import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';

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
    await CapsuleDatabase.prepareHive();

    status('Loading your capsules...');
    await Future.wait([
      CapsuleDatabase.open(),
      SettingsService.open(),
    ]);

    status('Setting up services...');
    await Future.wait([
      NotificationService().ensureStartupComplete(),
      MyAppTheme.preloadFonts(),
    ]);

    status('Almost ready...');
  }
}
