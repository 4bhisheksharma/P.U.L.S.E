import 'package:hive_flutter/hive_flutter.dart';

const _hiveBoxNames = ['capsules', 'app_settings'];

/// Initializes Hive, retrying once if the first attempt fails.
Future<void> initHiveSafe() async {
  try {
    await Hive.initFlutter();
  } catch (_) {
    try {
      await Hive.close();
    } catch (_) {}
    await Hive.initFlutter();
  }
}

/// Opens a Hive box, recreating it if the on-disk data is corrupt or incompatible.
Future<Box<T>> openHiveBoxSafe<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (e) {
    try {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
    } catch (_) {}

    await Hive.deleteBoxFromDisk(name);
    return await Hive.openBox<T>(name);
  }
}

/// Deletes all app Hive boxes and re-initializes storage (last-resort recovery).
Future<void> resetHiveStorage() async {
  try {
    await Hive.close();
  } catch (_) {}

  for (final name in _hiveBoxNames) {
    try {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
    } catch (_) {}
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (_) {}
  }

  await initHiveSafe();
}
