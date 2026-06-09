import 'package:flutter/material.dart';

class SearchResultsCounter extends StatelessWidget {
  final String query;
  final int resultCount;
  final int totalCount;
  final String singularLabel;
  final String pluralLabel;

  const SearchResultsCounter({
    super.key,
    required this.query,
    required this.resultCount,
    required this.totalCount,
    this.singularLabel = 'capsule',
    this.pluralLabel = 'capsules',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.39),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resultCount == 0
                    ? 'No $pluralLabel match "$query"'
                    : resultCount == 1
                    ? '1 $singularLabel found'
                    : '$resultCount $pluralLabel found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            if (resultCount < totalCount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'of $totalCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
