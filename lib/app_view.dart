import 'package:flutter/material.dart';
import 'package:pulse/screens/main_shell.dart';
import 'package:pulse/theme/my_app_theme.dart';

// Global navigator key for handling notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "P.U.L.S.E",
      theme: MyAppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainShell(),
    );
  }
}
