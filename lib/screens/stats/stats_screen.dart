import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/empty_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsules = CapsuleDatabase.getAllCapsules();
    final counts = CapsuleDatabase.getCapsuleCountByState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: MyAppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: capsules.isEmpty
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.insights_rounded,
                      title: 'No insights yet',
                      subtitle:
                          'Record your first capsule to start seeing stats '
                          'about your journey.',
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummaryCards(theme, counts, capsules.length),
                    const SizedBox(height: 16),
                    _buildHighlights(theme, capsules, counts),
                    const SizedBox(height: 24),
                    _buildEmotionDistribution(theme, capsules),
                    const SizedBox(height: 24),
                    _buildMonthlyChart(theme, capsules),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  // ---- Summary cards -----------------------------------------------------

  Widget _buildSummaryCards(
    ThemeData theme,
    Map<CapsuleState, int> counts,
    int total,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.inventory_2_outlined,
            value: total.toString(),
            label: 'Total',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.lock_outline,
            value: (counts[CapsuleState.locked] ?? 0).toString(),
            label: 'Locked',
            color: MyAppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline,
            value: (counts[CapsuleState.opened] ?? 0).toString(),
            label: 'Opened',
            color: MyAppTheme.successColor,
          ),
        ),
      ],
    );
  }

  // ---- Highlights (time, streak, top emotion) ----------------------------

  Widget _buildHighlights(
    ThemeData theme,
    List<VoiceCapsule> capsules,
    Map<CapsuleState, int> counts,
  ) {
    final totalSeconds = capsules.fold<int>(
      0,
      (sum, c) => sum + c.durationInSeconds,
    );
    final streak = _currentStreak(capsules);
    final topEmotion = _topEmotion(capsules);

    return Column(
      children: [
        _StatRow(
          icon: Icons.timer_outlined,
          label: 'Total recording time',
          value: _formatTotalTime(totalSeconds),
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.local_fire_department_outlined,
          label: 'Current streak',
          value: streak == 1 ? '1 day' : '$streak days',
          color: MyAppTheme.warningColor,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.lock_open_outlined,
          label: 'Ready to open',
          value: (counts[CapsuleState.unlockable] ?? 0).toString(),
          color: MyAppTheme.successColor,
        ),
        if (topEmotion != null) ...[
          const SizedBox(height: 12),
          _StatRow(
            icon: topEmotion.key.icon,
            label: 'Top emotion',
            value: topEmotion.key.label,
            color: theme.colorScheme.primary,
          ),
        ],
      ],
    );
  }

  // ---- Emotion distribution chart ----------------------------------------

  Widget _buildEmotionDistribution(
    ThemeData theme,
    List<VoiceCapsule> capsules,
  ) {
    final counts = <EmotionTag, int>{};
    for (final c in capsules) {
      final e = EmotionTag.fromString(c.emotionTag);
      if (e != null) counts[e] = (counts[e] ?? 0) + 1;
    }

    if (counts.isEmpty) return const SizedBox.shrink();

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.donut_small_rounded, title: 'Emotions'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _EmotionBar(
                  emotion: e.key,
                  value: e.value,
                  maxValue: maxValue,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---- Monthly recordings chart ------------------------------------------

  Widget _buildMonthlyChart(ThemeData theme, List<VoiceCapsule> capsules) {
    final now = DateTime.now();
    final buckets = <DateTime, int>{};
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      buckets[DateTime(month.year, month.month)] = 0;
    }
    for (final c in capsules) {
      final key = DateTime(c.recordedDate.year, c.recordedDate.month);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + 1;
      }
    }

    final entries = buckets.entries.toList();
    final maxValue = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.calendar_month_rounded,
          title: 'Last 6 months',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((e) {
                final fraction = maxValue == 0 ? 0.0 : e.value / maxValue;
                return Expanded(
                  child: _MonthBar(
                    label: DateFormat.MMM().format(e.key),
                    value: e.value,
                    fraction: fraction,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Computations ------------------------------------------------------

  int _currentStreak(List<VoiceCapsule> capsules) {
    if (capsules.isEmpty) return 0;
    final days = capsules
        .map((c) => DateTime(
              c.recordedDate.year,
              c.recordedDate.month,
              c.recordedDate.day,
            ))
        .toSet();

    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);

    // Allow the streak to count from today or yesterday.
    if (!days.contains(day)) {
      day = day.subtract(const Duration(days: 1));
      if (!days.contains(day)) return 0;
    }

    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  MapEntry<EmotionTag, int>? _topEmotion(List<VoiceCapsule> capsules) {
    final counts = <EmotionTag, int>{};
    for (final c in capsules) {
      final e = EmotionTag.fromString(c.emotionTag);
      if (e != null) counts[e] = (counts[e] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  String _formatTotalTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
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
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

class _EmotionBar extends StatelessWidget {
  final EmotionTag emotion;
  final int value;
  final int maxValue;

  const _EmotionBar({
    required this.emotion,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;

    return Row(
      children: [
        Icon(emotion.icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(
            emotion.label,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  final String label;
  final int value;
  final double fraction;

  const _MonthBar({
    required this.label,
    required this.value,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value > 0 ? value.toString() : '',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction <= 0 ? 0.02 : fraction,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  color: value > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
