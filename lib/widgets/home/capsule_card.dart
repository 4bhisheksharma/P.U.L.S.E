import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/live_countdown_timer.dart';

class CapsuleCard extends StatefulWidget {
  final VoiceCapsule capsule;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onBecameUnlockable;

  const CapsuleCard({
    super.key,
    required this.capsule,
    this.onTap,
    this.onShare,
    this.onRename,
    this.onDelete,
    this.onBecameUnlockable,
  });

  @override
  State<CapsuleCard> createState() => _CapsuleCardState();
}

class _CapsuleCardState extends State<CapsuleCard> {
  Timer? _timer;
  bool _wasLocked = true;

  VoiceCapsule get capsule => widget.capsule;

  @override
  void initState() {
    super.initState();
    _wasLocked = capsule.isLocked;
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(CapsuleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capsule.id != capsule.id ||
        oldWidget.capsule.unlockDate != capsule.unlockDate ||
        oldWidget.capsule.hasBeenOpened != capsule.hasBeenOpened) {
      _wasLocked = capsule.isLocked;
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (capsule.hasBeenOpened || !capsule.isLocked) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;

    final isLocked = capsule.isLocked;
    setState(() {});

    if (_wasLocked && !isLocked) {
      widget.onBecameUnlockable?.call();
      _timer?.cancel();
    }
    _wasLocked = isLocked;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emotion = EmotionTag.fromString(capsule.emotionTag);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatusIcon(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(theme),
                        const SizedBox(height: 6),
                        _buildSubtitle(theme, emotion),
                      ],
                    ),
                  ),
                  _buildPopupMenu(context, theme, isDark),
                ],
              ),
            ),
            if (capsule.isLocked) _buildProgressBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);
    final IconData icon;
    final Color color;

    switch (capsule.state) {
      case CapsuleState.locked:
        icon = Icons.lock;
        color = theme.colorScheme.primary;
        break;
      case CapsuleState.unlockable:
        icon = Icons.lock_open;
        color = MyAppTheme.warningColor;
        break;
      case CapsuleState.opened:
        icon = Icons.play_arrow_rounded;
        color = MyAppTheme.successColor;
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        Icon(
          capsule.state.icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            capsule.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(ThemeData theme, EmotionTag? emotion) {
    return Row(
      children: [
        if (emotion != null) ...[
          Icon(emotion.icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            _getSubtitleText(),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            capsule.durationFormatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = capsule.unlockProgress;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LiveCountdownTimer(
                capsule: capsule,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, ThemeData theme, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'share':
            widget.onShare?.call();
          case 'rename':
            widget.onRename?.call();
          case 'delete':
            widget.onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text('Share', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text('Rename', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  String _getSubtitleText() {
    final emotion = EmotionTag.fromString(capsule.emotionTag);
    final emotionText = emotion != null ? '${emotion.label} • ' : '';

    if (capsule.state == CapsuleState.opened) {
      return '${emotionText}Opened';
    } else if (capsule.state == CapsuleState.unlockable) {
      return '${emotionText}Ready to unlock!';
    } else {
      return emotionText.isNotEmpty
          ? emotionText.substring(0, emotionText.length - 3)
          : 'Locked';
    }
  }
}
