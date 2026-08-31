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
          icon: Icons.check_circle_outline_rounded,
          message: 'Renamed to "$newTitle"',
          backgroundColor: MyAppTheme.successColor,
        );
      }
    } else if (newTitle != null &&
        newTitle == capsule.title &&
        context.mounted) {
      showSnackBar(
        context,
        icon: Icons.info_outline_rounded,
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
        icon: Icons.lock_outline_rounded,
        message: 'Cannot share a locked capsule until it unlocks',
        backgroundColor: MyAppTheme.warningColor,
      );
      return;
    }

    final file = File(capsule.audioFilePath);
    if (!await file.exists()) {
      if (context.mounted) {
        showSnackBar(
          context,
          icon: Icons.error_outline_rounded,
          message: 'Audio file was not found on this device',
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

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    BuildContext context, {
    required IconData icon,
    required String message,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? MyAppTheme.surfaceColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: MyAppTheme.borderColor, width: 1),
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
