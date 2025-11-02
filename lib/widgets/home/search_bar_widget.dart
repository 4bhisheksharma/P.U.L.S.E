import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? hintText;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clearSearch() {
    widget.controller?.clear();
    widget.onChanged?.call('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller?.text.isNotEmpty ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused
              ? theme.colorScheme.primary.withAlpha(150)
              : const Color(0xFF2D2D3A),
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? theme.colorScheme.primary.withAlpha(50)
                : Colors.black.withAlpha(100),
            blurRadius: _isFocused ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: _isFocused ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused ? theme.colorScheme.primary : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? '   Search capsules...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (hasText)
            AnimatedScale(
              scale: hasText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: _clearSearch,
                splashRadius: 20,
                tooltip: 'Clear search',
              ),
            ),
        ],
      ),
    );
  }
}
