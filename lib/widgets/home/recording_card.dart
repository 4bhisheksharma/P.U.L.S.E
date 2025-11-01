import 'package:flutter/material.dart';

class RecordingCard extends StatelessWidget {
  final String title;
  final String date;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const RecordingCard({
    super.key,
    required this.title,
    required this.date,
    this.onPlay,
    this.onShare,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D3A) : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),

          // More options button
          PopupMenuButton(
            icon: Icon(
              Icons.more_horiz,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
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
                value: 'rename',
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
                value: 'delete',
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
          ),
        ],
      ),
    );
  }
}
