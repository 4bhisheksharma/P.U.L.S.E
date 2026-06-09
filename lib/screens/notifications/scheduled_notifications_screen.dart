import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final pending = await NotificationService().getPendingNotifications();
    final enabled = await NotificationService().areNotificationsEnabled();

    final capsules = CapsuleDatabase.getLockedCapsules()
      ..sort((a, b) => a.unlockDate.compareTo(b.unlockDate));

    setState(() {
      _pending = pending;
      _upcomingCapsules = capsules;
      _notificationsEnabled = enabled;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_notificationsEnabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MyAppTheme.warningColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MyAppTheme.warningColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            color: MyAppTheme.warningColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notifications are disabled. Enable them in system settings.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _SectionHeader(
                    icon: Icons.schedule_rounded,
                    title: 'Pending Notifications',
                    count: _pending.length,
                  ),
                  const SizedBox(height: 12),
                  if (_pending.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No pending notifications',
                      subtitle:
                          'Notifications will appear here when you schedule capsule unlocks.',
                    )
                  else
                    ..._pending.map(_buildPendingTile),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.lock_clock_rounded,
                    title: 'Upcoming Unlocks',
                    count: _upcomingCapsules.length,
                  ),
                  const SizedBox(height: 12),
                  if (_upcomingCapsules.isEmpty)
                    const EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No locked capsules',
                      subtitle: 'Create a capsule with a future unlock date.',
                    )
                  else
                    ..._upcomingCapsules.map(_buildCapsuleTile),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingTile(PendingNotificationRequest notification) {
    final theme = Theme.of(context);
    final capsule = notification.payload != null
        ? CapsuleDatabase.getCapsuleById(notification.payload!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Notification',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (capsule != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Unlocks ${capsule.timeRemainingFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(capsule.state.icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (emotion != null) ...[
                      Icon(
                        emotion.icon,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        capsule.timeRemainingFormatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
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
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleLarge),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
