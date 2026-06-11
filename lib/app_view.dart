import 'package:flutter/material.dart';
import 'package:pulse/screens/main_shell.dart';
import 'package:pulse/screens/splash/splash_screen.dart';
import 'package:pulse/screens/lock/lock_screen.dart';
import 'package:pulse/services/app_lock_service.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/theme/my_app_theme.dart';

// Global navigator key for handling notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> with WidgetsBindingObserver {
  bool _locked = false;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onBootstrapComplete() {
    setState(() {
      _bootstrapped = true;
      _locked = AppLockService.isLockEnabled;
      AppLockService.isSessionLocked = _locked;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().onAppReady();
    });
  }

  void _onUnlocked() {
    setState(() => _locked = false);
    AppLockService.isSessionLocked = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().processPendingNotificationTap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!AppLockService.isLockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Re-lock when the app leaves the foreground, unless a biometric prompt
      // (which itself backgrounds the app) is currently in progress.
      if (!AppLockService.authInProgress && !_locked) {
        setState(() => _locked = true);
        AppLockService.isSessionLocked = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "P.U.L.S.E",
      theme: MyAppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (_locked)
              // Wrap in its own Overlay so overlay-dependent widgets (tooltips,
              // text selection, etc.) work, since this sits outside the
              // app's Navigator.
              Positioned.fill(
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => LockScreen(
                        onUnlocked: _onUnlocked,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      home: _bootstrapped
          ? const MainShell()
          : SplashScreen(onComplete: _onBootstrapComplete),
    );
  }
}
