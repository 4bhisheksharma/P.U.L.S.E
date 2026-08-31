import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/empty_state.dart';

class ScheduledNotificationsScreen extends StatefulWidget {
  const ScheduledNotificationsScreen({super.key});

  @override
  State<ScheduledNotificationsScreen> createState() =>
      _ScheduledNotificationsScreenState();
}

class _ScheduledNotificationsScreenState
    extends State<ScheduledNotificationsScreen> {
  List<PendingNotificationRequest> _pending = [];
  List<VoiceCapsule> _upcomingCapsules = [];
  bool _isLoading = true;
  bool _isTesting = false;
  bool _notificationsEnabled = true;
  bool _exactAlarmsAllowed = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final pending = await NotificationService().getPendingNotifications();
    final enabled = await NotificationService().areNotificationsEnabled();
    final exactAllowed = await NotificationService().canScheduleExactAlarms();

    final capsules = CapsuleDatabase.getLockedCapsules()
      ..sort((a, b) => a.unlockDate.compareTo(b.unlockDate));

    if (mounted) {
      setState(() {
        _pending = pending;
        _upcomingCapsules = capsules;
        _notificationsEnabled = enabled;
        _exactAlarmsAllowed = exactAllowed;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isTesting = true);
    final success = await NotificationService().sendTestNotification(delaySeconds: 5);

    if (!mounted) return;
    setState(() => _isTesting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔔 Test notification scheduled for 5 seconds! Lock your phone or exit app to test.'),
          backgroundColor: MyAppTheme.successColor,
          duration: const Duration(seconds: 5),
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not schedule test alert. Please check app notification permissions in Settings.'),
          backgroundColor: MyAppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _rescheduleAll() async {
    setState(() => _isLoading = true);
    await NotificationService().rescheduleAllCapsuleNotifications();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All capsule notifications refreshed and verified'),
          backgroundColor: MyAppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Scheduled Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 22),
            tooltip: 'Reschedule all alerts',
            onPressed: _rescheduleAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                children: [
                  // Test notification quick card
                  _buildTestBanner(theme),
                  const SizedBox(height: 16),

                  // Permission warning if notifications are disabled
                  if (!_notificationsEnabled) ...[
                    _buildPermissionWarning(
                      theme: theme,
                      title: 'Notifications Disabled',
                      message: 'P.U.L.S.E cannot send you unlock reminders until notification permission is granted.',
                      buttonLabel: 'Enable in Settings',
                      onPressed: () async {
                        await openAppSettings();
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_notificationsEnabled && !_exactAlarmsAllowed) ...[
                    _buildPermissionWarning(
                      theme: theme,
                      title: 'Exact Alarms Restricted',
                      message: 'Android will deliver notifications with slight timing flexibility. For exact-minute alerts, allow "Alarms & Reminders".',
                      buttonLabel: 'Allow Exact Alarms',
                      onPressed: () async {
                        await NotificationService().requestPermissions();
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  _SectionHeader(
                    icon: Icons.schedule_rounded,
                    title: 'Active Alarms',
                    count: _pending.length,
                  ),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No pending alarms',
                      subtitle:
                          'When you create capsules with future unlock dates, scheduled alarms will appear here.',
                    )
                  else
                    ..._pending.map(_buildPendingTile),

                  const SizedBox(height: 24),
                  _SectionHeader(
                    icon: Icons.lock_clock_rounded,
                    title: 'Upcoming Unlocks',
                    count: _upcomingCapsules.length,
                  ),
                  const SizedBox(height: 10),
                  if (_upcomingCapsules.isEmpty)
                    const EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No locked capsules',
                      subtitle: 'Record a new capsule with a future unlock date.',
                    )
                  else
                    ..._upcomingCapsules.map(_buildCapsuleTile),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTestBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyAppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MyAppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: MyAppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Notification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verify sound and banners in 5 seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyAppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isTesting ? null : _sendTestNotification,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send Test', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning({
    required ThemeData theme,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyAppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MyAppTheme.warningColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: MyAppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: MyAppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyAppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MyAppTheme.warningColor, width: 1),
                foregroundColor: MyAppTheme.warningColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTile(PendingNotificationRequest notification) {
    final theme = Theme.of(context);
    final capsule = notification.payload != null
        ? CapsuleDatabase.getCapsuleById(notification.payload!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MyAppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: MyAppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Time Capsule Alert',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyAppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (capsule != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocks ${capsule.timeRemainingFormatted}',
                    style: TextStyle(
                      color: MyAppTheme.primaryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleTile(VoiceCapsule capsule) {
    final theme = Theme.of(context);
    final emotion = EmotionTag.fromString(capsule.emotionTag);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock_rounded, color: MyAppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (emotion != null) ...[
                      Icon(
                        emotion.icon,
                        size: 13,
                        color: MyAppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        'Unlocks ${DateFormat.yMMMd().add_jm().format(capsule.unlockDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MyAppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MyAppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: MyAppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MyAppTheme.borderColor, width: 1),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: MyAppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
