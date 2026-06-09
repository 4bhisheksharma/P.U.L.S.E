import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/services/settings_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/utils/capsule_actions.dart';
import 'package:pulse/widgets/common/empty_state.dart';
import 'package:pulse/widgets/common/search_results_counter.dart';
import 'package:pulse/widgets/home/search_bar_widget.dart';
import 'package:pulse/widgets/home/capsule_card.dart';
import 'package:pulse/screens/recording/recording_screen.dart';
import 'package:pulse/screens/player/audio_player_screen.dart';
import 'package:pulse/screens/notifications/scheduled_notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VoiceCapsule> _allCapsules = [];
  List<VoiceCapsule> _filteredCapsules = [];
  bool _isLoading = true;

  late CapsuleSortOption _sortOption;
  EmotionTag? _emotionFilter;

  @override
  void initState() {
    super.initState();
    _sortOption = CapsuleSortOption.fromName(SettingsService.sortOption);
    _emotionFilter = EmotionTag.fromString(SettingsService.emotionFilter);
    _loadCapsules();
  }

  bool get _hasActiveFilters =>
      _emotionFilter != null ||
      _sortOption != CapsuleSortOption.soonestUnlock;

  Future<void> _loadCapsules() async {
    setState(() => _isLoading = true);

    final allCapsules = CapsuleDatabase.getAllCapsules();
    _allCapsules = allCapsules.where((c) => !c.hasBeenOpened).toList();

    _applyFilters();

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var result = List<VoiceCapsule>.from(_allCapsules);

    // Emotion filter
    final emotion = _emotionFilter;
    if (emotion != null) {
      result = result
          .where((c) => c.emotionTag == emotion.name)
          .toList();
    }

    // Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((capsule) {
        final titleMatch = capsule.title.toLowerCase().contains(query);
        final descMatch =
            capsule.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descMatch;
      }).toList();
    }

    // Sorting
    switch (_sortOption) {
      case CapsuleSortOption.soonestUnlock:
        result.sort((a, b) => a.unlockDate.compareTo(b.unlockDate));
        break;
      case CapsuleSortOption.newestRecorded:
        result.sort((a, b) => b.recordedDate.compareTo(a.recordedDate));
        break;
      case CapsuleSortOption.longestDuration:
        result.sort(
          (a, b) => b.durationInSeconds.compareTo(a.durationInSeconds),
        );
        break;
    }

    _filteredCapsules = result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyAppTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/pulse.png',
              height: 55,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _hasActiveFilters ? Icons.tune_rounded : Icons.tune_outlined,
              color: _hasActiveFilters ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Sort & filter',
            onPressed: _showSortFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Scheduled notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduledNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(
                controller: _searchController,
                onChanged: _handleSearch,
                hintText: 'Search your capsules...',
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                SearchResultsCounter(
                  query: _searchController.text,
                  resultCount: _filteredCapsules.length,
                  totalCount: _allCapsules.length,
                ),
              ] else if (_hasActiveFilters) ...[
                const SizedBox(height: 16),
                _buildActiveFiltersBar(theme),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadCapsules,
                        child: _buildRecordingsList(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildActiveFiltersBar(ThemeData theme) {
    return Row(
      children: [
        Icon(_sortOption.icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _emotionFilter != null
                ? '${_sortOption.label} · ${_emotionFilter!.label}'
                : _sortOption.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _clearFilters,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text('Reset', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _sortOption = CapsuleSortOption.soonestUnlock;
      _emotionFilter = null;
      _applyFilters();
    });
    SettingsService.setSortOption(_sortOption.name);
    SettingsService.setEmotionFilter(null);
  }

  Future<void> _showSortFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);

            void updateSort(CapsuleSortOption option) {
              setSheetState(() => _sortOption = option);
              setState(() => _applyFilters());
              SettingsService.setSortOption(option.name);
            }

            void updateEmotion(EmotionTag? emotion) {
              setSheetState(() => _emotionFilter = emotion);
              setState(() => _applyFilters());
              SettingsService.setEmotionFilter(emotion?.name);
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: MyAppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('Sort by', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...CapsuleSortOption.values.map((option) {
                      final selected = _sortOption == option;
                      return _OptionTile(
                        icon: option.icon,
                        label: option.label,
                        selected: selected,
                        onTap: () => updateSort(option),
                      );
                    }),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.mood_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('Filter by emotion',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _emotionFilter == null,
                          onSelected: (_) => updateEmotion(null),
                          selectedColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                        ...EmotionTag.values.map((emotion) {
                          final selected = _emotionFilter == emotion;
                          return FilterChip(
                            avatar: Icon(
                              emotion.icon,
                              size: 18,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.iconTheme.color,
                            ),
                            label: Text(emotion.label),
                            selected: selected,
                            onSelected: (_) =>
                                updateEmotion(selected ? null : emotion),
                            selectedColor: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                            checkmarkColor: theme.colorScheme.primary,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSearch(String query) {
    setState(() => _applyFilters());
  }

  Widget _buildRecordingsList() {
    if (_filteredCapsules.isEmpty) {
      final hasNoCapsules = _allCapsules.isEmpty &&
          _searchController.text.isEmpty &&
          _emotionFilter == null;
      final isSearching =
          _searchController.text.isNotEmpty || _emotionFilter != null;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: hasNoCapsules
                ? Icons.mic_rounded
                : isSearching
                ? Icons.search_off_rounded
                : Icons.inbox_rounded,
            title: hasNoCapsules
                ? 'No capsules yet'
                : isSearching
                ? 'No capsules found'
                : 'All capsules played',
            subtitle: hasNoCapsules
                ? 'Create your first voice capsule for the future'
                : isSearching
                ? 'Try adjusting your search or filters'
                : 'Check "Played Capsules" to see opened messages',
            actionLabel: isSearching ? 'Clear Filters' : null,
            actionIcon: Icons.clear_all_rounded,
            onAction: isSearching
                ? () {
                    _searchController.clear();
                    _clearFilters();
                  }
                : null,
            footerText: hasNoCapsules ? 'Pull down to refresh' : null,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredCapsules.length,
      itemBuilder: (context, index) {
        final capsule = _filteredCapsules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CapsuleCard(
            capsule: capsule,
            onTap: () => _handlePlay(capsule),
            onShare: () => _handleShare(capsule),
            onRename: () => _handleRename(capsule),
            onDelete: () => _handleDelete(capsule),
          ),
        );
      },
    );
  }

  void _handlePlay(VoiceCapsule capsule) async {
    if (capsule.isLocked) {
      CapsuleActions.showSnackBar(
        context,
        icon: Icons.lock_outline,
        message: 'This capsule is still locked',
        backgroundColor: MyAppTheme.warningColor,
      );
      return;
    }

    var capsuleToPlay = capsule;
    if (!capsule.hasBeenOpened) {
      capsuleToPlay = capsule.copyWith(hasBeenOpened: true);
      await CapsuleDatabase.updateCapsule(capsuleToPlay);
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(capsule: capsuleToPlay),
        ),
      );
      _loadCapsules();
    }
  }

  void _handleShare(VoiceCapsule capsule) {
    CapsuleActions.shareCapsule(context: context, capsule: capsule);
  }

  void _handleRename(VoiceCapsule capsule) {
    CapsuleActions.showRenameDialog(
      context: context,
      capsule: capsule,
      onRenamed: _loadCapsules,
    );
  }

  void _handleDelete(VoiceCapsule capsule) async {
    await NotificationService().cancelCapsuleNotification(capsule.id);
    await CapsuleDatabase.deleteCapsule(capsule.id);
    await _loadCapsules();

    if (mounted) {
      CapsuleActions.showSnackBar(
        context,
        icon: Icons.delete_outline,
        message: 'Deleted: ${capsule.title}',
        backgroundColor: MyAppTheme.errorColor,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            await CapsuleDatabase.addCapsule(capsule);
            await NotificationService().scheduleCapsuleUnlockNotification(
              capsule,
            );
            await NotificationService().scheduleUnlockReminder(capsule);
            await _loadCapsules();
          },
        ),
      );
    }
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: MyAppTheme.primaryColor.withValues(alpha: 0.59),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const RecordingScreen()),
          );

          if (result == true && mounted) {
            _loadCapsules();
          }
        },
        backgroundColor: MyAppTheme.primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected ? theme.colorScheme.primary : null,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
