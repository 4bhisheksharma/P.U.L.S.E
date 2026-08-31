import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/capsule_notifier.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/common/empty_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    CapsuleNotifier.instance.revision.addListener(_onCapsulesChanged);
  }

  @override
  void dispose() {
    CapsuleNotifier.instance.revision.removeListener(_onCapsulesChanged);
    super.dispose();
  }

  void _onCapsulesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsules = CapsuleDatabase.getAllCapsules();
    final counts = CapsuleDatabase.getCapsuleCountByState();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Insights & Journey'),
        elevation: 0,
      ),
      body: SafeArea(
        child: capsules.isEmpty
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: [
                    EmptyState(
                      icon: Icons.insights_rounded,
                      lottieAsset: EmptyState.emptyLottie,
                      title: 'No insights recorded yet',
                      subtitle:
                          'Record your first voice capsule to start tracking your journey and timeline insights.',
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  children: [
                    _buildSummaryCards(theme, counts, capsules.length),
                    const SizedBox(height: 14),
                    _buildHighlights(theme, capsules, counts),
                    const SizedBox(height: 20),
                    _buildEmotionDistribution(theme, capsules),
                    const SizedBox(height: 20),
                    _buildMonthlyChart(theme, capsules),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {});
  }

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
            color: MyAppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.lock_clock_outlined,
            value: (counts[CapsuleState.locked] ?? 0).toString(),
            label: 'Locked',
            color: MyAppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            value: (counts[CapsuleState.opened] ?? 0).toString(),
            label: 'Opened',
            color: MyAppTheme.successColor,
          ),
        ),
      ],
    );
  }

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
          label: 'Total voice recorded',
          value: _formatTotalTime(totalSeconds),
          color: MyAppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        _StatRow(
          icon: Icons.local_fire_department_outlined,
          label: 'Recording streak',
          value: streak == 1 ? '1 day' : '$streak days',
          color: MyAppTheme.warningColor,
        ),
        const SizedBox(height: 8),
        _StatRow(
          icon: Icons.lock_open_rounded,
          label: 'Ready to unlock',
          value: (counts[CapsuleState.unlockable] ?? 0).toString(),
          color: MyAppTheme.successColor,
        ),
        if (topEmotion != null) ...[
          const SizedBox(height: 8),
          _StatRow(
            icon: topEmotion.key.icon,
            label: 'Dominant emotion',
            value: topEmotion.key.label,
            color: MyAppTheme.primaryColor,
          ),
        ],
      ],
    );
  }

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
        _SectionTitle(icon: Icons.mood_rounded, title: 'Emotion Breakdown'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyAppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MyAppTheme.borderColor, width: 1),
          ),
          child: Column(
            children: entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
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
          title: 'Recent Activity',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: MyAppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MyAppTheme.borderColor, width: 1),
          ),
          child: SizedBox(
            height: 130,
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyAppTheme.textSecondaryColor,
              fontSize: 11,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MyAppTheme.textColor,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
    return Row(
      children: [
        Icon(icon, size: 18, color: MyAppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
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
        Icon(emotion.icon, size: 16, color: MyAppTheme.primaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            emotion.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyAppTheme.textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  color: MyAppTheme.surfaceColor,
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.04, 1.0),
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: MyAppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
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
            color: MyAppTheme.textColor,
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction <= 0 ? 0.04 : fraction,
              child: Container(
                width: 16,
                decoration: BoxDecoration(
                  color: value > 0
                      ? MyAppTheme.primaryColor
                      : MyAppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: MyAppTheme.textSecondaryColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
