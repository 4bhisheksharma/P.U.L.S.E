import 'package:flutter/foundation.dart';

/// Broadcasts capsule data changes so screens refresh without manual reload.
class CapsuleNotifier {
  CapsuleNotifier._();

  static final CapsuleNotifier instance = CapsuleNotifier._();

  final ValueNotifier<int> revision = ValueNotifier(0);

  void notifyChanged() {
    revision.value++;
  }
}
