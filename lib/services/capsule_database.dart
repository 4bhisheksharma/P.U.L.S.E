import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_notifier.dart';
import 'package:pulse/utils/hive_storage.dart';

/// Service for managing voice capsules in Hive database
class CapsuleDatabase {
  static const String _boxName = 'capsules';
  static Box<VoiceCapsule>? _box;

  /// Initializes Hive and registers adapters (call once before opening boxes).
  static Future<void> prepareHive() async {
    await initHiveSafe();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VoiceCapsuleAdapter());
    }
  }

  /// Opens the capsules box. Requires [prepareHive] first.
  static Future<void> open() async {
    _box = await openHiveBoxSafe<VoiceCapsule>(_boxName);
  }

  /// Initialize Hive and open the capsules box
  static Future<void> init() async {
    await prepareHive();
    await open();
  }

  /// Get the capsules box
  static Box<VoiceCapsule> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Get all capsules
  static List<VoiceCapsule> getAllCapsules() {
    return box.values.toList();
  }

  /// Get a capsule by ID
  static VoiceCapsule? getCapsuleById(String id) {
    try {
      return box.values.firstWhere((capsule) => capsule.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a new capsule
  static Future<void> addCapsule(VoiceCapsule capsule) async {
    await box.put(capsule.id, capsule);
    CapsuleNotifier.instance.notifyChanged();
  }

  /// Update an existing capsule
  static Future<void> updateCapsule(VoiceCapsule capsule) async {
    await box.put(capsule.id, capsule);
    CapsuleNotifier.instance.notifyChanged();
  }

  /// Deletes the audio file at [path] if it exists.
  static Future<void> deleteAudioFileAt(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Delete a capsule and optionally its audio file.
  static Future<void> deleteCapsule(
    String id, {
    bool deleteAudioFile = true,
  }) async {
    final capsule = getCapsuleById(id);
    await box.delete(id);
    CapsuleNotifier.instance.notifyChanged();
    if (deleteAudioFile && capsule != null) {
      await deleteAudioFileAt(capsule.audioFilePath);
    }
  }

  /// Delete all capsules and their audio files.
  static Future<void> deleteAllCapsules() async {
    for (final capsule in box.values) {
      await deleteAudioFileAt(capsule.audioFilePath);
    }
    await box.clear();
    CapsuleNotifier.instance.notifyChanged();
  }

  /// Get locked capsules
  static List<VoiceCapsule> getLockedCapsules() {
    return box.values.where((capsule) => capsule.isLocked).toList();
  }

  /// Get unlockable capsules (ready to unlock but not opened yet)
  static List<VoiceCapsule> getUnlockableCapsules() {
    return box.values.where((capsule) => 
      capsule.state == CapsuleState.unlockable
    ).toList();
  }

  /// Get opened capsules
  static List<VoiceCapsule> getOpenedCapsules() {
    return box.values.where((capsule) => capsule.hasBeenOpened).toList();
  }

  /// Get capsules sorted by unlock date
  static List<VoiceCapsule> getCapsulesSortedByUnlockDate({
    bool ascending = true,
  }) {
    final capsules = getAllCapsules();
    capsules.sort((a, b) {
      return ascending
          ? a.unlockDate.compareTo(b.unlockDate)
          : b.unlockDate.compareTo(a.unlockDate);
    });
    return capsules;
  }

  /// Get capsules sorted by recorded date
  static List<VoiceCapsule> getCapsulesSortedByRecordedDate({
    bool ascending = false,
  }) {
    final capsules = getAllCapsules();
    capsules.sort((a, b) {
      return ascending
          ? a.recordedDate.compareTo(b.recordedDate)
          : b.recordedDate.compareTo(a.recordedDate);
    });
    return capsules;
  }

  /// Search capsules by title, emotion, or description
  static List<VoiceCapsule> searchCapsules(String query) {
    if (query.isEmpty) return getAllCapsules();
    
    final lowercaseQuery = query.toLowerCase();
    return box.values.where((capsule) {
      return capsule.title.toLowerCase().contains(lowercaseQuery) ||
          (capsule.emotionTag?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (capsule.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Get count of capsules by state
  static Map<CapsuleState, int> getCapsuleCountByState() {
    final counts = <CapsuleState, int>{
      CapsuleState.locked: 0,
      CapsuleState.unlockable: 0,
      CapsuleState.opened: 0,
    };

    for (final capsule in box.values) {
      counts[capsule.state] = (counts[capsule.state] ?? 0) + 1;
    }

    return counts;
  }

  /// Check if database is empty
  static bool get isEmpty => box.isEmpty;

  /// Get total number of capsules
  static int get count => box.length;

  /// Close the database
  static Future<void> close() async {
    await box.close();
  }
}
