import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/services/app_lock_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
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
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Incorrect PIN. Try again.');
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
        backgroundColor: MyAppTheme.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyAppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: MyAppTheme.borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: MyAppTheme.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'P.U.L.S.E is Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _error ?? 'Enter your 4-digit PIN to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _error != null
                        ? MyAppTheme.errorColor
                        : MyAppTheme.textSecondaryColor,
                    fontWeight: _error != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const Spacer(flex: 1),
                PinEntry(
                  onCompleted: _verifyPin,
                  biometricButton: showBiometric
                      ? IconButton(
                          onPressed: _tryBiometric,
                          icon: const Icon(Icons.fingerprint_rounded),
                          iconSize: 28,
                          color: MyAppTheme.primaryColor,
                          tooltip: 'Unlock with biometrics',
                        )
                      : null,
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
