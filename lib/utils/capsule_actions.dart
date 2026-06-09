import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';

class CapsuleActions {
  static Future<void> showRenameDialog({
    required BuildContext context,
    required VoiceCapsule capsule,
    required VoidCallback onRenamed,
  }) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initialTitle: capsule.title),
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != capsule.title &&
        context.mounted) {
      await CapsuleDatabase.updateCapsule(
        capsule.copyWith(title: newTitle),
      );
      onRenamed();
      if (context.mounted) {
        showSnackBar(
          context,
          icon: Icons.edit_outlined,
          message: 'Renamed to "$newTitle"',
        );
      }
    } else if (newTitle != null &&
        newTitle == capsule.title &&
        context.mounted) {
      showSnackBar(
        context,
        icon: Icons.info_outline,
        message: 'Title unchanged',
      );
    }
  }

  static Future<void> shareCapsule({
    required BuildContext context,
    required VoiceCapsule capsule,
  }) async {
    if (capsule.isLocked) {
      showSnackBar(
        context,
        icon: Icons.lock_outline,
        message: 'Cannot share a locked capsule',
        backgroundColor: MyAppTheme.warningColor,
      );
      return;
    }

    final file = File(capsule.audioFilePath);
    if (!await file.exists()) {
      if (context.mounted) {
        showSnackBar(
          context,
          icon: Icons.error_outline,
          message: 'Audio file not found',
          backgroundColor: MyAppTheme.errorColor,
        );
      }
      return;
    }

    final description = capsule.description != null
        ? '\n${capsule.description}'
        : '';

    await Share.shareXFiles(
      [XFile(capsule.audioFilePath)],
      text: '${capsule.title}$description',
      subject: capsule.title,
    );
  }

  static void showSnackBar(
    BuildContext context, {
    required IconData icon,
    required String message,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  static Future<void> showStatisticsSheet(BuildContext context) async {
    final counts = CapsuleDatabase.getCapsuleCountByState();
    final total = CapsuleDatabase.count;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Capsule Statistics',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StatRow(
              icon: Icons.inventory_2_outlined,
              label: 'Total Capsules',
              value: total.toString(),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.lock_outline,
              label: 'Locked',
              value: (counts[CapsuleState.locked] ?? 0).toString(),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.lock_open_outlined,
              label: 'Unlockable',
              value: (counts[CapsuleState.unlockable] ?? 0).toString(),
              color: MyAppTheme.warningColor,
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.check_circle_outline,
              label: 'Opened',
              value: (counts[CapsuleState.opened] ?? 0).toString(),
              color: MyAppTheme.successColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String initialTitle;

  const _RenameDialog({required this.initialTitle});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      Navigator.pop(context, title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Capsule'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Enter a new title',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
