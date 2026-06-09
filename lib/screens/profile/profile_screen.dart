import 'package:flutter/material.dart';
import 'package:pulse/screens/notifications/scheduled_notifications_screen.dart';
import 'package:pulse/screens/security/security_screen.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = CapsuleDatabase.count;
    final lockEnabled = SettingsService.appLockEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: MyAppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(theme, total),
            const SizedBox(height: 28),
            _SectionLabel(label: 'Settings'),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.shield_outlined,
              title: 'Security',
              subtitle: lockEnabled ? 'App lock is on' : 'App lock is off',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              title: 'Scheduled Notifications',
              subtitle: 'See upcoming capsule unlocks',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScheduledNotificationsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            _SectionLabel(label: 'About'),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.info_outline,
              title: 'About P.U.L.S.E',
              subtitle: 'Version 1.0.0',
              onTap: _showAbout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/icon.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'P.U.L.S.E',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Personal Unseen Locker for Special Experience',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  total == 1 ? '1 capsule created' : '$total capsules created',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    Share.share(
      'Check out P.U.L.S.E - Personal Unseen Locker for Special Experience',
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.bodySmall?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.iconTheme.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
