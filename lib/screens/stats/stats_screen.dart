import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = CapsuleDatabase.getCapsuleCountByState();
    final total = CapsuleDatabase.count;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: MyAppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your capsules at a glance',
                style: theme.textTheme.bodyMedium,
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
      ),
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
