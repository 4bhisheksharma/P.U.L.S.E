import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/services/app_lock_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/widgets/common/pin_entry.dart';

/// Full-screen lock shown over the app when [AppLockService.isLockEnabled].
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    final available = await AppLockService.isBiometricAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);

    if (available && SettingsService.biometricEnabled) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await AppLockService.authenticateBiometric('Unlock P.U.L.S.E');
    if (ok && mounted) {
      widget.onUnlocked();
    }
  }

  void _verifyPin(String pin) {
    if (SettingsService.verifyPin(pin)) {
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBiometric =
        _biometricAvailable && SettingsService.biometricEnabled;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'P.U.L.S.E is locked',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Enter your PIN to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _error != null
                        ? theme.colorScheme.error
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 40),
                PinEntry(
                  onCompleted: _verifyPin,
                  biometricButton: showBiometric
                      ? IconButton(
                          onPressed: _tryBiometric,
                          icon: const Icon(Icons.fingerprint),
                          iconSize: 32,
                          color: theme.colorScheme.primary,
                          tooltip: 'Use biometrics',
                        )
                      : null,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
