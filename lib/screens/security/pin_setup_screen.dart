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
        _error = 'PINs did not match. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirming = _firstEntry != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Set Passcode'),
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
                    isConfirming ? Icons.lock_reset_rounded : Icons.lock_outline_rounded,
                    size: 30,
                    color: MyAppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isConfirming ? 'Confirm your PIN' : 'Create a 4-Digit PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isConfirming
                    ? 'Re-enter your 4 digits to confirm passcode'
                    : 'This PIN will be required to unlock your capsules',
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
                key: ValueKey(isConfirming),
                onCompleted: _onCompleted,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
