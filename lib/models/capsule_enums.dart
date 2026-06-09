import 'package:flutter/material.dart';

/// Enum representing different emotional states when recording a capsule
enum EmotionTag {
  hopeful('Hopeful', Icons.auto_awesome, 'Feeling optimistic about the future'),
  grateful(
    'Grateful',
    Icons.volunteer_activism,
    'Thankful for what you have',
  ),
  anxious('Anxious', Icons.psychology_alt, 'Feeling worried or nervous'),
  excited('Excited', Icons.celebration, 'Full of enthusiasm and energy'),
  sad('Sad', Icons.sentiment_dissatisfied, 'Feeling down or melancholic'),
  confused('Confused', Icons.help_outline, 'Uncertain about something'),
  determined('Determined', Icons.fitness_center, 'Focused and resolved'),
  nostalgic('Nostalgic', Icons.wb_twilight, 'Reminiscing about the past'),
  peaceful('Peaceful', Icons.spa, 'Calm and content'),
  ambitious('Ambitious', Icons.rocket_launch, 'Driven to achieve goals'),
  reflective('Reflective', Icons.lightbulb_outline, 'Deep in thought'),
  joyful('Joyful', Icons.sentiment_very_satisfied, 'Happy and cheerful');

  final String label;
  final IconData icon;
  final String description;

  const EmotionTag(this.label, this.icon, this.description);

  /// Get display name with label only (icon rendered separately in UI)
  String get displayName => label;

  /// Convert from string value
  static EmotionTag? fromString(String? value) {
    if (value == null) return null;
    try {
      return EmotionTag.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Enum representing the current state of a capsule
enum CapsuleState {
  /// Capsule is still locked, waiting for unlock date
  locked,

  /// Capsule is unlocked but hasn't been opened yet
  unlockable,

  /// Capsule has been unlocked and opened
  opened;

  /// Get icon for the state
  IconData get icon {
    switch (this) {
      case CapsuleState.locked:
        return Icons.lock;
      case CapsuleState.unlockable:
        return Icons.lock_open;
      case CapsuleState.opened:
        return Icons.check_circle;
    }
  }

  /// Get color code for the state
  String get colorHex {
    switch (this) {
      case CapsuleState.locked:
        return '#7C73FF';
      case CapsuleState.unlockable:
        return '#FFB74D';
      case CapsuleState.opened:
        return '#4CAF50';
    }
  }
}
