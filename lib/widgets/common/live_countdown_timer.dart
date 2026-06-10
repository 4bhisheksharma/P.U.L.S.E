import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';

/// Displays a countdown for locked capsules. Rebuild the parent every second
/// (e.g. from [CapsuleCard]) to keep the label live.
class LiveCountdownTimer extends StatelessWidget {
  final VoiceCapsule capsule;
  final TextStyle? textStyle;

  const LiveCountdownTimer({super.key, required this.capsule, this.textStyle});

  static String format(VoiceCapsule capsule) {
    final now = DateTime.now();
    final difference = capsule.unlockDate.difference(now);

    if (difference.isNegative) {
      return 'Ready to unlock!';
    }

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s remaining';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      final secs = difference.inSeconds % 60;
      return '${mins}m ${secs}s remaining';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final mins = difference.inMinutes % 60;
      return '${hours}h ${mins}m remaining';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      return '${days}d ${hours}h remaining';
    }

    return capsule.timeRemainingFormatted;
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = format(capsule);
    final isReady = timeRemaining == 'Ready to unlock!';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isReady) ...[
          Icon(
            Icons.lock_open_outlined,
            size: 14,
            color: textStyle?.color ?? Colors.green.shade300,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          timeRemaining,
          style:
              textStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: capsule.isLocked
                    ? Colors.orange.shade300
                    : Colors.green.shade300,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
