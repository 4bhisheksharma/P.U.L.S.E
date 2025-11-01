import 'package:flutter/material.dart';
import 'package:pulse/screens/screens.dart';
import 'package:pulse/theme/my_app_theme.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "P.U.L.S.E",
      theme: MyAppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
      routes: {'/played': (context) => const PlayedCapsulesScreen()},
    );
  }
}
