import 'package:flutter/material.dart';
import 'package:pulse/screens/home_screen.dart';
import 'package:pulse/screens/played/played_capsules_screen.dart';
import 'package:pulse/screens/stats/stats_screen.dart';
import 'package:pulse/screens/profile/profile_screen.dart';
import 'package:pulse/services/capsule_notifier.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/theme/my_app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _pageCache = <int, Widget>{};

  Widget _pageAt(int index) {
    return _pageCache.putIfAbsent(index, () {
      return switch (index) {
        0 => const HomeScreen(),
        1 => const PlayedCapsulesScreen(),
        2 => const StatsScreen(),
        3 => const ProfileScreen(),
        _ => const SizedBox.shrink(),
      };
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().ensureStartupComplete();
      NotificationService().processPendingNotificationTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (index) {
          if (index == _currentIndex || _pageCache.containsKey(index)) {
            return _pageAt(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          CapsuleNotifier.instance.notifyChanged();
        },
        backgroundColor: MyAppTheme.surfaceColor,
        indicatorColor: MyAppTheme.primaryColor.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history),
            label: 'Played',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
