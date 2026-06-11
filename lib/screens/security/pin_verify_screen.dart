import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/widgets/common/pin_entry.dart';

/// Single-step PIN verification. Pops with `true` on success.
class PinVerifyScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const PinVerifyScreen({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle = 'Confirm your current PIN to continue',
  });

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  String? _error;

  void _verify(String pin) {
    if (SettingsService.verifyPin(pin)) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _error != null
                      ? theme.colorScheme.error
                      : theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PinEntry(
                key: ValueKey(_error),
                onCompleted: _verify,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
