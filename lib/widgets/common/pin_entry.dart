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
        const SizedBox(height: 36),
        _buildKeypad(context),
      ],
    );
  }

  Widget _buildDots(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final filled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? MyAppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: filled ? MyAppTheme.primaryColor : MyAppTheme.borderColor,
              width: 1.8,
            ),
            boxShadow: [
              if (filled)
                BoxShadow(
                  color: MyAppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
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
                iconSize: 22,
                color: MyAppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlot(Widget? child) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Center(child: child ?? const SizedBox.shrink()),
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: MyAppTheme.cardColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _addDigit(digit),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MyAppTheme.borderColor, width: 1),
            ),
            child: Center(
              child: Text(
                digit,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
