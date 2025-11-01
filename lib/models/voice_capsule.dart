import 'package:hive/hive.dart';
import 'package:pulse/models/capsule_enums.dart';

part 'voice_capsule.g.dart';

/// Represents a voice capsule - a recorded message locked until a specific date
@HiveType(typeId: 0)
class VoiceCapsule extends HiveObject {
  /// Unique identifier for the capsule
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String audioFilePath;

  @HiveField(3)
  final DateTime recordedDate;

  @HiveField(4)
  final DateTime unlockDate;

  @HiveField(5)
  final bool hasBeenOpened;

  @HiveField(6)
  final int durationInSeconds;

  @HiveField(7)
  final String? emotionTag;

  @HiveField(8)
  final String? description;

  @HiveField(9)
  final int? fileSizeBytes;

  VoiceCapsule({
    required this.id,
    required this.title,
    required this.audioFilePath,
    required this.recordedDate,
    required this.unlockDate,
    this.hasBeenOpened = false,
    required this.durationInSeconds,
    this.emotionTag,
    this.description,
    this.fileSizeBytes,
  });

  bool get isUnlocked {
    return DateTime.now().isAfter(unlockDate) ||
        DateTime.now().isAtSameMomentAs(unlockDate);
  }

  bool get isLocked {
    return !isUnlocked;
  }

  CapsuleState get state {
    if (hasBeenOpened) {
      return CapsuleState.opened;
    } else if (isUnlocked) {
      return CapsuleState.unlockable;
    } else {
      return CapsuleState.locked;
    }
  }

  /// Returns the duration remaining until unlock
  Duration get timeRemaining {
    if (isUnlocked) return Duration.zero;
    return unlockDate.difference(DateTime.now());
  }

  /// Returns the time elapsed since recording
  Duration get timeSinceRecorded {
    return DateTime.now().difference(recordedDate);
  }

  /// Returns the total lock duration (from recording to unlock)
  Duration get totalLockDuration {
    return unlockDate.difference(recordedDate);
  }

  /// Returns progress as a percentage (0.0 to 1.0)
  double get unlockProgress {
    if (isUnlocked) return 1.0;

    final total = totalLockDuration.inSeconds;
    final elapsed = timeSinceRecorded.inSeconds;

    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Returns a human-readable time remaining string
  String get timeRemainingFormatted {
    if (isUnlocked) return 'Unlocked';

    final duration = timeRemaining;

    if (duration.inDays > 365) {
      final years = (duration.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} remaining';
    } else if (duration.inDays > 30) {
      final months = (duration.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} remaining';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'} remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'} remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'} remaining';
    } else {
      return 'Less than a minute remaining';
    }
  }

  /// Returns formatted duration of the audio
  String get durationFormatted {
    final minutes = (durationInSeconds / 60).floor();
    final seconds = durationInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a copy with modified fields
  VoiceCapsule copyWith({
    String? id,
    String? title,
    String? audioFilePath,
    DateTime? recordedDate,
    DateTime? unlockDate,
    bool? hasBeenOpened,
    int? durationInSeconds,
    String? emotionTag,
    String? description,
    int? fileSizeBytes,
  }) {
    return VoiceCapsule(
      id: id ?? this.id,
      title: title ?? this.title,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      recordedDate: recordedDate ?? this.recordedDate,
      unlockDate: unlockDate ?? this.unlockDate,
      hasBeenOpened: hasBeenOpened ?? this.hasBeenOpened,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      emotionTag: emotionTag ?? this.emotionTag,
      description: description ?? this.description,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  /// Converts the model to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'audioFilePath': audioFilePath,
      'recordedDate': recordedDate.toIso8601String(),
      'unlockDate': unlockDate.toIso8601String(),
      'hasBeenOpened': hasBeenOpened,
      'durationInSeconds': durationInSeconds,
      'emotionTag': emotionTag,
      'description': description,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  /// Creates a model from a Map
  factory VoiceCapsule.fromMap(Map<String, dynamic> map) {
    return VoiceCapsule(
      id: map['id'] as String,
      title: map['title'] as String,
      audioFilePath: map['audioFilePath'] as String,
      recordedDate: DateTime.parse(map['recordedDate'] as String),
      unlockDate: DateTime.parse(map['unlockDate'] as String),
      hasBeenOpened: map['hasBeenOpened'] as bool? ?? false,
      durationInSeconds: map['durationInSeconds'] as int,
      emotionTag: map['emotionTag'] as String?,
      description: map['description'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int?,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() => toMap();

  /// Creates from JSON
  factory VoiceCapsule.fromJson(Map<String, dynamic> json) =>
      VoiceCapsule.fromMap(json);

  @override
  String toString() {
    return 'VoiceCapsule(id: $id, title: $title, unlockDate: $unlockDate, isLocked: $isLocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoiceCapsule &&
        other.id == id &&
        other.title == title &&
        other.audioFilePath == audioFilePath &&
        other.recordedDate == recordedDate &&
        other.unlockDate == unlockDate &&
        other.hasBeenOpened == hasBeenOpened &&
        other.durationInSeconds == durationInSeconds &&
        other.emotionTag == emotionTag &&
        other.description == description &&
        other.fileSizeBytes == fileSizeBytes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      audioFilePath,
      recordedDate,
      unlockDate,
      hasBeenOpened,
      durationInSeconds,
      emotionTag,
      description,
      fileSizeBytes,
    );
  }
}
