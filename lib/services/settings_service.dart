import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight key-value settings store backed by Hive.
class SettingsService {
  static const String _boxName = 'app_settings';

  // Keys
  static const String _kAppLockEnabled = 'appLockEnabled';
  static const String _kPinHash = 'pinHash';
  static const String _kBiometricEnabled = 'biometricEnabled';
  static const String _kSortOption = 'sortOption';
  static const String _kEmotionFilter = 'emotionFilter';

  // A static salt for hashing the PIN. Local privacy only (not server auth).
  static const String _salt = 'pulse::v1::lock';

  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box get _settings {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw Exception('SettingsService not initialized. Call init() first.');
    }
    return box;
  }

  // ---- App lock ----------------------------------------------------------

  static bool get appLockEnabled =>
      _settings.get(_kAppLockEnabled, defaultValue: false) as bool;

  static Future<void> setAppLockEnabled(bool value) async {
    await _settings.put(_kAppLockEnabled, value);
  }

  static bool get hasPin => (_settings.get(_kPinHash) as String?) != null;

  static bool get biometricEnabled =>
      _settings.get(_kBiometricEnabled, defaultValue: false) as bool;

  static Future<void> setBiometricEnabled(bool value) async {
    await _settings.put(_kBiometricEnabled, value);
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode('$_salt::$pin');
    return sha256.convert(bytes).toString();
  }

  static Future<void> setPin(String pin) async {
    await _settings.put(_kPinHash, _hashPin(pin));
  }

  static bool verifyPin(String pin) {
    final stored = _settings.get(_kPinHash) as String?;
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Fully disable the lock and remove the stored PIN.
  static Future<void> clearLock() async {
    await _settings.delete(_kPinHash);
    await _settings.put(_kAppLockEnabled, false);
    await _settings.put(_kBiometricEnabled, false);
  }

  // ---- Home sorting / filtering -----------------------------------------

  static String get sortOption =>
      _settings.get(_kSortOption, defaultValue: 'soonestUnlock') as String;

  static Future<void> setSortOption(String value) async {
    await _settings.put(_kSortOption, value);
  }

  static String? get emotionFilter =>
      _settings.get(_kEmotionFilter) as String?;

  static Future<void> setEmotionFilter(String? value) async {
    if (value == null) {
      await _settings.delete(_kEmotionFilter);
    } else {
      await _settings.put(_kEmotionFilter, value);
    }
  }
}
