import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/pin_entry.dart';

/// Single-step PIN verification. Pops with `true` on success.
class PinVerifyScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const PinVerifyScreen({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle = 'Confirm your 4-digit PIN to continue',
  });

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  String? _error;

  void _verify(String pin) {
    if (SettingsService.verifyPin(pin)) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Incorrect PIN. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MyAppTheme.primaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 30,
                    color: MyAppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MyAppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MyAppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: MyAppTheme.errorColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(flex: 1),
              PinEntry(
                key: ValueKey(_error),
                onCompleted: _verify,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
