import 'package:flutter/material.dart';
import 'package:pulse/screens/notifications/scheduled_notifications_screen.dart';
import 'package:pulse/screens/security/security_screen.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/constants/app_info.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _privacyPolicyUrl = 'https://app.abhishek-sharma.com.np/pulse/privacy';
  static const _dataDeletionUrl = 'https://app.abhishek-sharma.com.np/pulse/account-deletion';

  final String _versionLabel = AppInfo.versionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = CapsuleDatabase.count;
    final lockEnabled = SettingsService.appLockEnabled;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            _buildHeader(theme, total),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Preferences & Security'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.lock_outline_rounded,
              title: 'App Lock & PIN',
              subtitle: lockEnabled ? 'Protected with PIN / Biometrics' : 'App lock is disabled',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.notifications_active_outlined,
              title: 'Scheduled Alerts & Test',
              subtitle: 'Verify notifications and check alarms',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScheduledNotificationsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'Privacy & Policies'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn how your recordings are kept private',
              onTap: () => _openUrl(_privacyPolicyUrl),
            ),
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Data Deletion Policy',
              subtitle: 'Information on removing your local data',
              onTap: () => _openUrl(_dataDeletionUrl),
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'Storage & Reset'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.delete_forever_rounded,
              title: 'Clear All App Data',
              subtitle: 'Permanently remove all audio, capsules, and lock',
              iconColor: MyAppTheme.errorColor,
              onTap: _confirmDeleteAllData,
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'About'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.share_rounded,
              title: 'Share P.U.L.S.E',
              subtitle: _versionLabel,
              onTap: _showAbout,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MyAppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/icon.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'P.U.L.S.E',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Personal Unseen Locker for Special Experience',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyAppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: MyAppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MyAppTheme.borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 15,
                  color: MyAppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  total == 1 ? '1 voice capsule saved' : '$total voice capsules saved',
                  style: TextStyle(
                    color: MyAppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open link'),
          backgroundColor: MyAppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAllData() async {
    final total = CapsuleDatabase.count;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: Text(
          total == 0
              ? 'This will remove your app lock PIN and cancel all scheduled alarms. This cannot be undone.'
              : 'This will permanently delete all $total voice capsule${total == 1 ? '' : 's'}, '
                  'including all audio files, PIN settings, and scheduled notifications.\n\n'
                  'This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MyAppTheme.errorColor),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await NotificationService().cancelAllNotifications();
    await CapsuleDatabase.deleteAllCapsules();
    await SettingsService.clearLock();
    await SettingsService.clearConsumedColdStartNotificationPayload();

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All capsules and data permanently deleted'),
        backgroundColor: MyAppTheme.successColor,
      ),
    );
  }

  void _showAbout() {
    Share.share(
      'Send voice messages to your future self with P.U.L.S.E (Personal Unseen Locker for Special Experience)!',
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: MyAppTheme.textMutedColor,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? MyAppTheme.primaryColor;

    return Material(
      color: MyAppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MyAppTheme.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: MyAppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: MyAppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
