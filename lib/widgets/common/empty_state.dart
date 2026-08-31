import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pulse/theme/my_app_theme.dart';

class EmptyState extends StatelessWidget {
  static const emptyLottie = 'assets/lottie/empty.json';

  final IconData icon;
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? footerText;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: 180,
                height: 180,
                child: Lottie.asset(
                  lottieAsset!,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MyAppTheme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MyAppTheme.borderColor,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: MyAppTheme.primaryColor,
                ),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MyAppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            if (footerText != null) ...[
              const SizedBox(height: 12),
              Text(
                footerText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyAppTheme.textMutedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
