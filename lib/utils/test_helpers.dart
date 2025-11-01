import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:uuid/uuid.dart';

/// Helper functions for testing lock features during development
class TestHelpers {
  static const _uuid = Uuid();

  /// Add test capsules with various lock states for testing
  ///
  /// This creates:
  /// - 1 unlockable capsule (ready NOW)
  /// - 1 unlocking in 30 seconds (to test real-time unlock)
  /// - 1 unlocking in 2 minutes (to test countdown)
  /// - 1 locked for 1 hour
  /// - 1 locked for 1 day
  static Future<void> addTestCapsules() async {
    final now = DateTime.now();

    final testCapsules = [
      // Unlockable RIGHT NOW
      VoiceCapsule(
        id: _uuid.v4(),
        title: '✅ TEST: Ready to Open',
        audioFilePath: '/test/ready_now.m4a',
        recordedDate: now.subtract(const Duration(hours: 1)),
        unlockDate: now.subtract(const Duration(seconds: 1)),
        durationInSeconds: 60,
        emotionTag: EmotionTag.joyful.name,
        description: 'This should be unlockable immediately!',
      ),

      // Unlocks in 30 seconds
      VoiceCapsule(
        id: _uuid.v4(),
        title: '⏰ TEST: Unlocks in 30s',
        audioFilePath: '/test/unlock_30s.m4a',
        recordedDate: now,
        unlockDate: now.add(const Duration(seconds: 30)),
        durationInSeconds: 45,
        emotionTag: EmotionTag.excited.name,
        description: 'Wait 30 seconds and refresh to see it unlock!',
      ),

      // Unlocks in 2 minutes
      VoiceCapsule(
        id: _uuid.v4(),
        title: '⏰ TEST: Unlocks in 2m',
        audioFilePath: '/test/unlock_2m.m4a',
        recordedDate: now,
        unlockDate: now.add(const Duration(minutes: 2)),
        durationInSeconds: 90,
        emotionTag: EmotionTag.hopeful.name,
        description: 'Wait 2 minutes to test countdown progress',
      ),

      // Locked for 1 hour
      VoiceCapsule(
        id: _uuid.v4(),
        title: '🔒 TEST: Locked 1 hour',
        audioFilePath: '/test/locked_1h.m4a',
        recordedDate: now,
        unlockDate: now.add(const Duration(hours: 1)),
        durationInSeconds: 120,
        emotionTag: EmotionTag.determined.name,
        description: 'Testing hour-based countdown',
      ),

      // Locked for 1 day
      VoiceCapsule(
        id: _uuid.v4(),
        title: '🔒 TEST: Locked 1 day',
        audioFilePath: '/test/locked_1d.m4a',
        recordedDate: now,
        unlockDate: now.add(const Duration(days: 1)),
        durationInSeconds: 180,
        emotionTag: EmotionTag.peaceful.name,
        description: 'Testing day-based countdown',
      ),
    ];

    for (final capsule in testCapsules) {
      await CapsuleDatabase.addCapsule(capsule);
    }
  }

  /// Clear all test capsules (ones with "TEST:" in title)
  static Future<void> clearTestCapsules() async {
    final allCapsules = CapsuleDatabase.getAllCapsules();
    for (final capsule in allCapsules) {
      if (capsule.title.contains('TEST:')) {
        await CapsuleDatabase.deleteCapsule(capsule.id);
      }
    }
  }

  /// Create a capsule that unlocks at a specific time
  static Future<VoiceCapsule> createTimedCapsule({
    required String title,
    required Duration unlockAfter,
    EmotionTag emotion = EmotionTag.hopeful,
  }) async {
    final capsule = VoiceCapsule(
      id: _uuid.v4(),
      title: title,
      audioFilePath: '/test/${_uuid.v4()}.m4a',
      recordedDate: DateTime.now(),
      unlockDate: DateTime.now().add(unlockAfter),
      durationInSeconds: 60,
      emotionTag: emotion.name,
      description: 'Custom test capsule - unlocks in ${unlockAfter.toString()}',
    );

    await CapsuleDatabase.addCapsule(capsule);
    return capsule;
  }

  /// Force unlock a capsule by changing its unlock date to the past
  static Future<void> forceUnlockCapsule(String capsuleId) async {
    final allCapsules = CapsuleDatabase.getAllCapsules();
    final capsule = allCapsules.firstWhere((c) => c.id == capsuleId);

    final unlockedCapsule = VoiceCapsule(
      id: capsule.id,
      title: capsule.title,
      audioFilePath: capsule.audioFilePath,
      recordedDate: capsule.recordedDate,
      unlockDate: DateTime.now().subtract(const Duration(seconds: 1)),
      durationInSeconds: capsule.durationInSeconds,
      emotionTag: capsule.emotionTag,
      description: capsule.description,
      hasBeenOpened: capsule.hasBeenOpened,
    );

    await CapsuleDatabase.updateCapsule(unlockedCapsule);
  }

  /// Get statistics about lock states
  static Map<String, int> getLockStatistics() {
    final counts = CapsuleDatabase.getCapsuleCountByState();
    final all = CapsuleDatabase.getAllCapsules();

    return {
      'total': all.length,
      'locked': counts[CapsuleState.locked] ?? 0,
      'unlockable': counts[CapsuleState.unlockable] ?? 0,
      'opened': counts[CapsuleState.opened] ?? 0,
    };
  }
}
