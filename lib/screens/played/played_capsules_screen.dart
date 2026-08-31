import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/capsule_notifier.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/utils/capsule_actions.dart';
import 'package:pulse/widgets/common/empty_state.dart';
import 'package:pulse/widgets/common/search_results_counter.dart';
import 'package:pulse/widgets/home/search_bar_widget.dart';
import 'package:pulse/widgets/home/swipeable_capsule_card.dart';
import 'package:pulse/screens/player/audio_player_screen.dart';

class PlayedCapsulesScreen extends StatefulWidget {
  const PlayedCapsulesScreen({super.key});

  @override
  State<PlayedCapsulesScreen> createState() => _PlayedCapsulesScreenState();
}

class _PlayedCapsulesScreenState extends State<PlayedCapsulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VoiceCapsule> _capsules = [];
  List<VoiceCapsule> _filteredCapsules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    CapsuleNotifier.instance.revision.addListener(_onCapsulesChanged);
    _loadCapsules(showLoader: true);
  }

  void _onCapsulesChanged() {
    if (mounted) _loadCapsules();
  }

  Future<void> _loadCapsules({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
      await Future<void>.delayed(Duration.zero);
    }

    final allCapsules = CapsuleDatabase.getAllCapsules();
    _capsules = allCapsules.where((c) => c.hasBeenOpened).toList();
    _capsules.sort((a, b) => b.unlockDate.compareTo(a.unlockDate));
    _applySearchFilter();

    if (mounted) setState(() => _isLoading = false);
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredCapsules = _capsules;
      return;
    }

    _filteredCapsules = _capsules.where((capsule) {
      final titleMatch = capsule.title.toLowerCase().contains(query);
      final descMatch =
          capsule.description?.toLowerCase().contains(query) ?? false;
      return titleMatch || descMatch;
    }).toList();
  }

  @override
  void dispose() {
    CapsuleNotifier.instance.revision.removeListener(_onCapsulesChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Played Capsules'),
        elevation: 0,
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
                hintText: 'Search played messages...',
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                SearchResultsCounter(
                  query: _searchController.text,
                  resultCount: _filteredCapsules.length,
                  totalCount: _capsules.length,
                  singularLabel: 'played capsule',
                  pluralLabel: 'played capsules',
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadCapsules,
                        child: _buildCapsulesList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    setState(_applySearchFilter);
  }

  Widget _buildCapsulesList() {
    if (_filteredCapsules.isEmpty) {
      final hasNoCapsules = _capsules.isEmpty && _searchController.text.isEmpty;
      final isSearching = _searchController.text.isNotEmpty;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: hasNoCapsules
                ? Icons.history_toggle_off_rounded
                : Icons.search_off_rounded,
            lottieAsset: CapsuleDatabase.isEmpty ? EmptyState.emptyLottie : null,
            title: hasNoCapsules
                ? 'No opened capsules yet'
                : 'No capsules match search',
            subtitle: hasNoCapsules
                ? 'Once a locked capsule unlocks and you listen to it, it will be safely archived here.'
                : 'Try adjusting your search query',
            actionLabel: isSearching ? 'Clear Search' : null,
            actionIcon: Icons.clear_all_rounded,
            onAction: isSearching
                ? () {
                    _searchController.clear();
                    _handleSearch('');
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
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final capsule = _filteredCapsules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SwipeableCapsuleCard(
            capsule: capsule,
            onTap: () => _handlePlay(capsule),
            onShare: () => _handleShare(capsule),
            onRename: () => _handleRename(capsule),
            onDismissed: () => _handleDelete(capsule, showUndo: true),
          ),
        );
      },
    );
  }

  void _handlePlay(VoiceCapsule capsule) async {
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

  void _handleDelete(VoiceCapsule capsule, {bool showUndo = false}) async {
    await NotificationService().cancelCapsuleNotification(capsule.id);
    await CapsuleDatabase.deleteCapsule(
      capsule.id,
      deleteAudioFile: !showUndo,
    );
    await _loadCapsules();

    if (mounted && showUndo) {
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
}
