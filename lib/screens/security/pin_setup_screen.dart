import 'package:flutter/material.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/pin_entry.dart';

/// Two-step PIN creation flow. Pops with the chosen PIN (String) on success.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstEntry;
  String? _error;

  void _onCompleted(String pin) {
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _error = null;
      });
    } else if (_firstEntry == pin) {
      Navigator.pop(context, pin);
    } else {
      setState(() {
        _firstEntry = null;
        _error = 'PINs did not match. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirming = _firstEntry != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                isConfirming ? Icons.lock_reset_rounded : Icons.lock_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isConfirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isConfirming
                    ? 'Re-enter the PIN to confirm'
                    : 'You will use this to unlock the app',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyAppTheme.errorColor,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              PinEntry(
                key: ValueKey(isConfirming),
                onCompleted: _onCompleted,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
