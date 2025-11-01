import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';

/// A widget that displays a live countdown timer for locked capsules
/// Updates every second to show real-time progress
class LiveCountdownTimer extends StatefulWidget {
  final VoiceCapsule capsule;
  final TextStyle? textStyle;

  const LiveCountdownTimer({super.key, required this.capsule, this.textStyle});

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  Timer? _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();

    // Only start timer if capsule is locked
    if (widget.capsule.isLocked) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _updateTimeRemaining();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = _formatTimeRemaining();
    });
  }

  String _formatTimeRemaining() {
    final now = DateTime.now();
    final unlockDate = widget.capsule.unlockDate;
    final difference = unlockDate.difference(now);

    if (difference.isNegative) {
      return 'Ready to unlock! ⏰';
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
    } else {
      return widget.capsule.timeRemainingFormatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeRemaining,
      style:
          widget.textStyle ??
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.capsule.isLocked
                ? Colors.orange.shade300
                : Colors.green.shade300,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
