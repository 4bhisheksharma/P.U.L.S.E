import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';

class CapsuleCard extends StatelessWidget {
  final VoiceCapsule capsule;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const CapsuleCard({
    super.key,
    required this.capsule,
    this.onTap,
    this.onShare,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emotion = EmotionTag.fromString(capsule.emotionTag);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(isDark), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),

            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Play/Lock button
                _buildActionButton(context),
                const SizedBox(width: 16),

                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(theme),
                      const SizedBox(height: 6),
                      _buildSubtitle(theme, emotion),
                    ],
                  ),
                ),

                // More options
                _buildPopupMenu(context, theme, isDark),
              ],
            ),
          ),

          // Progress bar (only for locked capsules)
          if (capsule.isLocked) _buildProgressBar(theme),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final IconData icon;
    final Color color;

    switch (capsule.state) {
      case CapsuleState.locked:
        icon = Icons.lock;
        color = theme.colorScheme.primary;
        break;
      case CapsuleState.unlockable:
        icon = Icons.lock_open;
        color = Colors.orange;
        break;
      case CapsuleState.opened:
        icon = Icons.play_arrow_rounded;
        color = Colors.green;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        Text(capsule.state.icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            capsule.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(ThemeData theme, EmotionTag? emotion) {
    return Row(
      children: [
        if (emotion != null) ...[
          Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            _getSubtitleText(),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            capsule.durationFormatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                capsule.timeRemainingFormatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              Text(
                '${(capsule.unlockProgress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: LinearProgressIndicator(
            value: capsule.unlockProgress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, ThemeData theme, bool isDark) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_horiz,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: onShare,
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text('Share', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onRename,
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: theme.iconTheme.color),
              const SizedBox(width: 12),
              Text('Rename', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBorderColor(bool isDark) {
    if (capsule.state == CapsuleState.unlockable) {
      return Colors.orange.withOpacity(0.5);
    }
    return isDark ? const Color(0xFF2D2D3A) : const Color(0xFFE0E0E0);
  }

  String _getSubtitleText() {
    final emotion = EmotionTag.fromString(capsule.emotionTag);
    final emotionText = emotion != null ? '${emotion.label} • ' : '';

    if (capsule.state == CapsuleState.opened) {
      return '${emotionText}Opened';
    } else if (capsule.state == CapsuleState.unlockable) {
      return '${emotionText}Ready to unlock!';
    } else {
      return emotionText.isNotEmpty
          ? emotionText.substring(0, emotionText.length - 3)
          : 'Locked';
    }
  }
}
