import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/theme/my_app_theme.dart';

/// A reusable PIN keypad with dot indicators. Calls [onCompleted] when [length]
/// digits have been entered, then clears itself so the caller can react.
class PinEntry extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final Widget? biometricButton;

  const PinEntry({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.biometricButton,
  });

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  String _pin = '';

  void _addDigit(String digit) {
    if (_pin.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);

    if (_pin.length == widget.length) {
      final value = _pin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pin = '');
      });
      widget.onCompleted(value);
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDots(context),
        const SizedBox(height: 40),
        _buildKeypad(context),
      ],
    );
  }

  Widget _buildDots(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final filled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? theme.colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: filled
                  ? theme.colorScheme.primary
                  : MyAppTheme.borderColor,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((d) => _buildKey(context, d)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSlot(widget.biometricButton),
            _buildKey(context, '0'),
            _buildSlot(
              IconButton(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace_outlined),
                iconSize: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlot(Widget? child) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Center(child: child ?? const SizedBox.shrink()),
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: theme.cardColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _addDigit(digit),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: Text(
                digit,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
