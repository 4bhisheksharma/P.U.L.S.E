/// Enum representing different emotional states when recording a capsule
enum EmotionTag {
  hopeful('Hopeful', '🌟', 'Feeling optimistic about the future'),
  grateful('Grateful', '🙏', 'Thankful for what you have'),
  anxious('Anxious', '😰', 'Feeling worried or nervous'),
  excited('Excited', '🎉', 'Full of enthusiasm and energy'),
  sad('Sad', '😢', 'Feeling down or melancholic'),
  confused('Confused', '🤔', 'Uncertain about something'),
  determined('Determined', '💪', 'Focused and resolved'),
  nostalgic('Nostalgic', '🌅', 'Reminiscing about the past'),
  peaceful('Peaceful', '🧘', 'Calm and content'),
  ambitious('Ambitious', '🚀', 'Driven to achieve goals'),
  reflective('Reflective', '💭', 'Deep in thought'),
  joyful('Joyful', '😊', 'Happy and cheerful');

  final String label;
  final String emoji;
  final String description;

  const EmotionTag(this.label, this.emoji, this.description);

  /// Get display name with emoji
  String get displayName => '$emoji $label';

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
  String get icon {
    switch (this) {
      case CapsuleState.locked:
        return '🔒';
      case CapsuleState.unlockable:
        return '⏰';
      case CapsuleState.opened:
        return '✅';
    }
  }

  /// Get color code for the state
  String get colorHex {
    switch (this) {
      case CapsuleState.locked:
        return '#7C73FF'; // Purple
      case CapsuleState.unlockable:
        return '#FFB74D'; // Orange
      case CapsuleState.opened:
        return '#4CAF50'; // Green
    }
  }
}
