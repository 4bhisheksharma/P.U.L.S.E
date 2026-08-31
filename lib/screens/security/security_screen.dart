import 'package:flutter/material.dart';
import 'package:pulse/screens/security/pin_setup_screen.dart';
import 'package:pulse/screens/security/pin_verify_screen.dart';
import 'package:pulse/services/app_lock_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/utils/capsule_actions.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await AppLockService.isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<String?> _setupPin() async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  Future<bool> _verifyCurrentPinOrBiometric(String reason) async {
    if (SettingsService.biometricEnabled &&
        await AppLockService.isBiometricAvailable()) {
      return AppLockService.authenticateBiometric(reason);
    }

    if (!mounted) return false;

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PinVerifyScreen(
          title: 'Verify PIN',
          subtitle: reason,
        ),
      ),
    );
    return verified == true;
  }

  Future<void> _toggleAppLock(bool enable) async {
    if (enable) {
      if (!SettingsService.hasPin) {
        final pin = await _setupPin();
        if (pin == null) return;
        await SettingsService.setPin(pin);
      }
      await SettingsService.setAppLockEnabled(true);
    } else {
      final verified = await _verifyCurrentPinOrBiometric(
        'Enter your PIN to turn off app lock',
      );
      if (!verified) return;
      await SettingsService.clearLock();
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePin() async {
    final verified = await _verifyCurrentPinOrBiometric(
      'Enter your current PIN to change it',
    );
    if (!verified) return;

    final pin = await _setupPin();
    if (pin == null) return;
    await SettingsService.setPin(pin);
    if (mounted) {
      CapsuleActions.showSnackBar(
        context,
        icon: Icons.check_circle_outline,
        message: 'PIN successfully updated',
      );
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final ok = await AppLockService.authenticateBiometric(
        'Confirm biometric authentication to enable',
      );
      if (!ok) {
        if (mounted) {
          CapsuleActions.showSnackBar(
            context,
            icon: Icons.error_outline,
            message: 'Biometric authentication was cancelled or failed',
            backgroundColor: MyAppTheme.warningColor,
          );
        }
        return;
      }
    }
    await SettingsService.setBiometricEnabled(enable);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockEnabled = SettingsService.appLockEnabled;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('App Security & Lock'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MyAppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MyAppTheme.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MyAppTheme.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: MyAppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Lock P.U.L.S.E with a PIN or biometrics so only you can access your recorded voice capsules.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MyAppTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'App Lock',
              subtitle: lockEnabled
                  ? 'Required when opening the app'
                  : 'Disabled',
              trailing: Switch(
                value: lockEnabled,
                activeThumbColor: MyAppTheme.primaryColor,
                onChanged: _toggleAppLock,
              ),
            ),
            if (lockEnabled) ...[
              const SizedBox(height: 8),
              _SettingTile(
                icon: Icons.pin_outlined,
                title: 'Change 4-Digit PIN',
                subtitle: 'Update your security passcode',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _changePin,
              ),
              const SizedBox(height: 8),
              _SettingTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Unlock',
                subtitle: _biometricAvailable
                    ? 'Use Fingerprint or Face ID'
                    : 'Not supported on this device',
                trailing: Switch(
                  value: SettingsService.biometricEnabled && _biometricAvailable,
                  activeThumbColor: MyAppTheme.primaryColor,
                  onChanged: _biometricAvailable ? _toggleBiometric : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: MyAppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MyAppTheme.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MyAppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: MyAppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: MyAppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
