import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/home/capsule_card.dart';

class SwipeableCapsuleCard extends StatelessWidget {
  final VoiceCapsule capsule;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback onDismissed;

  const SwipeableCapsuleCard({
    super.key,
    required this.capsule,
    required this.onDismissed,
    this.onTap,
    this.onShare,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(capsule.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      movementDuration: const Duration(milliseconds: 200),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: MyAppTheme.errorColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: CapsuleCard(
        capsule: capsule,
        onTap: onTap,
        onShare: onShare,
        onRename: onRename,
        onDelete: onDismissed,
      ),
    );
  }
}
