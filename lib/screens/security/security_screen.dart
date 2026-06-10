import 'package:flutter/material.dart';
import 'package:pulse/screens/security/pin_setup_screen.dart';
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

  Future<void> _toggleAppLock(bool enable) async {
    if (enable) {
      if (!SettingsService.hasPin) {
        final pin = await _setupPin();
        if (pin == null) return;
        await SettingsService.setPin(pin);
      }
      await SettingsService.setAppLockEnabled(true);
    } else {
      await SettingsService.clearLock();
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePin() async {
    final pin = await _setupPin();
    if (pin == null) return;
    await SettingsService.setPin(pin);
    if (mounted) {
      CapsuleActions.showSnackBar(
        context,
        icon: Icons.check_circle_outline,
        message: 'PIN updated',
      );
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final ok = await AppLockService.authenticateBiometric(
        'Confirm to enable biometric unlock',
      );
      if (!ok) {
        if (mounted) {
          CapsuleActions.showSnackBar(
            context,
            icon: Icons.error_outline,
            message: 'Biometric verification failed',
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
        title: const Text('Security'),
        backgroundColor: MyAppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lock P.U.L.S.E with a PIN or biometrics so only you can '
                    'open your private capsules.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SettingTile(
              icon: Icons.lock_outline,
              title: 'App Lock',
              subtitle: lockEnabled
                  ? 'Required every time you open the app'
                  : 'Off',
              trailing: Switch(
                value: lockEnabled,
                onChanged: _toggleAppLock,
              ),
            ),
            if (lockEnabled) ...[
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.pin_outlined,
                title: 'Change PIN',
                subtitle: 'Update your 4-digit PIN',
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePin,
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.fingerprint,
                title: 'Unlock with biometrics',
                subtitle: _biometricAvailable
                    ? 'Use fingerprint or face unlock'
                    : 'Not available on this device',
                trailing: Switch(
                  value: SettingsService.biometricEnabled &&
                      _biometricAvailable,
                  onChanged:
                      _biometricAvailable ? _toggleBiometric : null,
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
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
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
