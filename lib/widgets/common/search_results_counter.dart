import 'package:flutter/material.dart';
import 'package:pulse/theme/my_app_theme.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: MyAppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MyAppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: MyAppTheme.primaryColor,
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
                color: MyAppTheme.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
          if (resultCount < totalCount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MyAppTheme.cardColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MyAppTheme.borderColor, width: 0.8),
              ),
              child: Text(
                'of $totalCount',
                style: TextStyle(
                  color: MyAppTheme.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
