import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
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
  List<VoiceCapsule> _capsules = [];
  List<VoiceCapsule> _filteredCapsules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    setState(() => _isLoading = true);

    final allCapsules = CapsuleDatabase.getAllCapsules();
    _capsules = allCapsules.where((c) => !c.hasBeenOpened).toList();
    _capsules.sort((a, b) => a.unlockDate.compareTo(b.unlockDate));
    _filteredCapsules = _capsules;

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  totalCount: _capsules.length,
                ),
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

  void _handleSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCapsules = _capsules;
      } else {
        _filteredCapsules = _capsules.where((capsule) {
          final titleMatch = capsule.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          final descMatch =
              capsule.description?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false;
          return titleMatch || descMatch;
        }).toList();
      }
    });
  }

  Widget _buildRecordingsList() {
    if (_filteredCapsules.isEmpty) {
      final hasNoCapsules = _capsules.isEmpty && _searchController.text.isEmpty;
      final isSearching = _searchController.text.isNotEmpty;

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
                ? 'Try adjusting your search or clear filters'
                : 'Check "Played Capsules" to see opened messages',
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
