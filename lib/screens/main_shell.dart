import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/screens/home_screen.dart';
import 'package:pulse/screens/played/played_capsules_screen.dart';
import 'package:pulse/screens/stats/stats_screen.dart';
import 'package:pulse/screens/profile/profile_screen.dart';
import 'package:pulse/services/app_update_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService.instance.checkForUpdate(context);
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MyAppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: MyAppTheme.borderColor,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 64,
            indicatorColor: MyAppTheme.primaryColor.withValues(alpha: 0.16),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined, size: 22),
                selectedIcon: Icon(Icons.inventory_2_rounded, size: 22),
                label: 'Capsules',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded, size: 22),
                selectedIcon: Icon(Icons.history_toggle_off_rounded, size: 22),
                label: 'Played',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_rounded, size: 22),
                selectedIcon: Icon(Icons.insights, size: 22),
                label: 'Insights',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 22),
                selectedIcon: Icon(Icons.person_rounded, size: 22),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
