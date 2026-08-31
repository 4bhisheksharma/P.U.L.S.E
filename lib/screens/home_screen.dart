import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/capsule_notifier.dart';
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

enum CapsuleTabFilter { all, locked, ready }

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
  int _pendingNotificationsCount = 0;

  CapsuleTabFilter _tabFilter = CapsuleTabFilter.all;
  late CapsuleSortOption _sortOption;
  EmotionTag? _emotionFilter;

  @override
  void initState() {
    super.initState();
    _sortOption = CapsuleSortOption.fromName(SettingsService.sortOption);
    _emotionFilter = EmotionTag.fromString(SettingsService.emotionFilter);
    CapsuleNotifier.instance.revision.addListener(_onCapsulesChanged);
    _loadCapsules(showLoader: true);
    _checkPendingNotifications();
  }

  bool get _hasActiveFilters =>
      _emotionFilter != null ||
      _sortOption != CapsuleSortOption.soonestUnlock ||
      _tabFilter != CapsuleTabFilter.all;

  void _onCapsulesChanged() {
    if (mounted) {
      _loadCapsules();
      _checkPendingNotifications();
    }
  }

  Future<void> _checkPendingNotifications() async {
    try {
      final pending = await NotificationService().getPendingNotifications();
      if (mounted) {
        setState(() => _pendingNotificationsCount = pending.length);
      }
    } catch (_) {}
  }

  Future<void> _loadCapsules({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
      await Future<void>.delayed(Duration.zero);
    }

    final allCapsules = CapsuleDatabase.getAllCapsules();
    _allCapsules = allCapsules.where((c) => !c.hasBeenOpened).toList();
    _applyFilters();

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var result = List<VoiceCapsule>.from(_allCapsules);

    // Tab filter (All, Locked, Ready)
    switch (_tabFilter) {
      case CapsuleTabFilter.all:
        break;
      case CapsuleTabFilter.locked:
        result = result.where((c) => c.state == CapsuleState.locked).toList();
        break;
      case CapsuleTabFilter.ready:
        result = result.where((c) => c.state == CapsuleState.unlockable).toList();
        break;
    }

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
    CapsuleNotifier.instance.revision.removeListener(_onCapsulesChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockedCount = _allCapsules.where((c) => c.state == CapsuleState.locked).length;
    final readyCount = _allCapsules.where((c) => c.state == CapsuleState.unlockable).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: MyAppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: MyAppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'P.U.L.S.E',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _hasActiveFilters ? Icons.tune_rounded : Icons.tune_outlined,
                  color: _hasActiveFilters ? MyAppTheme.primaryColor : null,
                  size: 22,
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: MyAppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Sort & filter',
            onPressed: _showSortFilterSheet,
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 22),
                if (_pendingNotificationsCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: MyAppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        _pendingNotificationsCount > 9 ? '9+' : '$_pendingNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Scheduled notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduledNotificationsScreen(),
                ),
              ).then((_) => _checkPendingNotifications());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SearchBarWidget(
                controller: _searchController,
                onChanged: _handleSearch,
                hintText: 'Search voice capsules...',
              ),
              const SizedBox(height: 12),
              _buildFilterChipsRow(theme, lockedCount, readyCount),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                SearchResultsCounter(
                  query: _searchController.text,
                  resultCount: _filteredCapsules.length,
                  totalCount: _allCapsules.length,
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadCapsules();
                          await _checkPendingNotifications();
                        },
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

  Widget _buildFilterChipsRow(ThemeData theme, int lockedCount, int readyCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabChip(
            label: 'All (${_allCapsules.length})',
            isSelected: _tabFilter == CapsuleTabFilter.all,
            onTap: () {
              setState(() {
                _tabFilter = CapsuleTabFilter.all;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Locked ($lockedCount)',
            icon: Icons.lock_outline,
            isSelected: _tabFilter == CapsuleTabFilter.locked,
            onTap: () {
              setState(() {
                _tabFilter = CapsuleTabFilter.locked;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          _buildTabChip(
            label: 'Ready ($readyCount)',
            icon: Icons.lock_open_rounded,
            isSelected: _tabFilter == CapsuleTabFilter.ready,
            accentColor: MyAppTheme.successColor,
            onTap: () {
              setState(() {
                _tabFilter = CapsuleTabFilter.ready;
                _applyFilters();
              });
            },
          ),
          if (_emotionFilter != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MyAppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: MyAppTheme.primaryColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_emotionFilter!.icon, size: 14, color: MyAppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _emotionFilter!.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MyAppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _emotionFilter = null;
                        _applyFilters();
                      });
                      SettingsService.setEmotionFilter(null);
                    },
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final activeColor = accentColor ?? MyAppTheme.primaryColor;

    return Material(
      color: isSelected
          ? activeColor.withValues(alpha: 0.16)
          : MyAppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.5)
                  : MyAppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? activeColor : MyAppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : MyAppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _sortOption = CapsuleSortOption.soonestUnlock;
      _emotionFilter = null;
      _tabFilter = CapsuleTabFilter.all;
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
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: MyAppTheme.borderLightColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.sort_rounded, color: theme.colorScheme.primary, size: 20),
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.mood_rounded, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Filter by emotion', style: theme.textTheme.titleMedium),
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
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                        ...EmotionTag.values.map((emotion) {
                          final selected = _emotionFilter == emotion;
                          return FilterChip(
                            avatar: Icon(
                              emotion.icon,
                              size: 16,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.iconTheme.color,
                            ),
                            label: Text(emotion.label),
                            selected: selected,
                            onSelected: (_) => updateEmotion(selected ? null : emotion),
                            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
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
            lottieAsset: hasNoCapsules && CapsuleDatabase.isEmpty
                ? EmptyState.emptyLottie
                : null,
            title: hasNoCapsules
                ? 'No active capsules'
                : isSearching
                ? 'No capsules match search'
                : 'All capsules played',
            subtitle: hasNoCapsules
                ? 'Record your first voice message to unlock in the future'
                : isSearching
                ? 'Try adjusting your search or filters'
                : 'Listen to opened messages in the Played tab',
            actionLabel: hasNoCapsules
                ? 'Record a Capsule'
                : isSearching
                ? 'Clear Filters'
                : null,
            actionIcon: hasNoCapsules
                ? Icons.mic_rounded
                : Icons.clear_all_rounded,
            onAction: hasNoCapsules
                ? () => _openRecordingScreen()
                : isSearching
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
      padding: const EdgeInsets.only(bottom: 90),
      itemBuilder: (context, index) {
        final capsule = _filteredCapsules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CapsuleCard(
            key: ValueKey(capsule.id),
            capsule: capsule,
            onTap: () => _handlePlay(capsule),
            onShare: () => _handleShare(capsule),
            onRename: () => _handleRename(capsule),
            onDelete: () => _handleDelete(capsule),
            onBecameUnlockable: _loadCapsules,
          ),
        );
      },
    );
  }

  void _handlePlay(VoiceCapsule capsule) async {
    if (capsule.isLocked) {
      CapsuleActions.showSnackBar(
        context,
        icon: Icons.lock_clock_rounded,
        message: 'This capsule is still locked (${capsule.timeRemainingFormatted})',
        backgroundColor: MyAppTheme.warningColor,
      );
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(capsule: capsule),
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
    await CapsuleDatabase.deleteCapsule(capsule.id, deleteAudioFile: false);
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
      ).closed.then((reason) {
        if (reason != SnackBarClosedReason.action) {
          CapsuleDatabase.deleteAudioFileAt(capsule.audioFilePath);
        }
      });
    }
  }

  Future<void> _openRecordingScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const RecordingScreen()),
    );

    if (result == true && mounted) {
      _loadCapsules();
      _checkPendingNotifications();
    }
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyAppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openRecordingScreen,
        backgroundColor: MyAppTheme.primaryColor,
        elevation: 0,
        icon: const Icon(Icons.mic_rounded, size: 22, color: Colors.white),
        label: const Text(
          'Record Capsule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
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
            : MyAppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
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
                    size: 19,
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
