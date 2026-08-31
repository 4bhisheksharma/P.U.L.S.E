import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final emotion = EmotionTag.fromString(capsule.emotionTag);
    final isUnlockable = capsule.state == CapsuleState.unlockable;
    final isLocked = capsule.state == CapsuleState.locked;

    return Container(
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlockable
              ? MyAppTheme.successColor.withValues(alpha: 0.35)
              : MyAppTheme.borderColor,
          width: isUnlockable ? 1.2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeadingIcon(context),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capsule.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildSubtitleRow(theme, emotion),
                            if (capsule.description != null &&
                                capsule.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                capsule.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: MyAppTheme.textMutedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildPopupMenu(context, theme),
                    ],
                  ),
                ),
                if (isLocked) _buildProgressFooter(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final IconData icon;
    final Color color;
    final Color bgColor;

    switch (capsule.state) {
      case CapsuleState.locked:
        icon = Icons.lock_clock_rounded;
        color = MyAppTheme.primaryColor;
        bgColor = MyAppTheme.primaryColor.withValues(alpha: 0.12);
        break;
      case CapsuleState.unlockable:
        icon = Icons.lock_open_rounded;
        color = MyAppTheme.successColor;
        bgColor = MyAppTheme.successColor.withValues(alpha: 0.14);
        break;
      case CapsuleState.opened:
        icon = Icons.play_arrow_rounded;
        color = MyAppTheme.textSecondaryColor;
        bgColor = MyAppTheme.surfaceColor;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildSubtitleRow(ThemeData theme, EmotionTag? emotion) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (emotion != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: MyAppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: MyAppTheme.borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emotion.icon, size: 12, color: MyAppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  emotion.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: MyAppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: MyAppTheme.borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq_rounded, size: 12, color: MyAppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                capsule.durationFormatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MyAppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressFooter(ThemeData theme) {
    final progress = capsule.unlockProgress;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LiveCountdownTimer(
                capsule: capsule,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  color: MyAppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyAppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: MyAppTheme.surfaceColor,
            valueColor: AlwaysStoppedAnimation<Color>(MyAppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: MyAppTheme.textMutedColor,
      ),
      color: MyAppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: MyAppTheme.borderColor, width: 1),
      ),
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
              Icon(Icons.share_outlined, size: 18, color: MyAppTheme.textColor),
              const SizedBox(width: 12),
              Text('Share', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: MyAppTheme.textColor),
              const SizedBox(width: 12),
              Text('Rename', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: MyAppTheme.errorColor),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: MyAppTheme.errorColor, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
