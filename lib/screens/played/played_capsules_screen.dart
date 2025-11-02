import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/widgets/home/search_bar_widget.dart';
import 'package:pulse/widgets/home/capsule_card.dart';
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
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    setState(() => _isLoading = true);

    // Load only played capsules from database
    final allCapsules = CapsuleDatabase.getAllCapsules();
    _capsules = allCapsules.where((c) => c.hasBeenOpened).toList();

    // Sort by unlock date (most recent first)
    _capsules.sort((a, b) => b.unlockDate.compareTo(a.unlockDate));
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
        title: const Text('Played Capsules'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              SearchBarWidget(
                controller: _searchController,
                onChanged: _handleSearch,
                hintText: 'Search played capsules...',
              ),

              // Search results counter
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSearchResultsCounter(),
              ],

              const SizedBox(height: 24),

              // Capsules list with pull-to-refresh
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

  Widget _buildSearchResultsCounter() {
    final theme = Theme.of(context);
    final resultCount = _filteredCapsules.length;
    final totalCount = _capsules.length;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(100),
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
                    ? 'No capsules match "${_searchController.text}"'
                    : resultCount == 1
                    ? '1 played capsule found'
                    : '$resultCount played capsules found',
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
                  color: theme.colorScheme.primary.withAlpha(50),
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

  Widget _buildCapsulesList() {
    if (_filteredCapsules.isEmpty) {
      final hasNoCapsules = _capsules.isEmpty && _searchController.text.isEmpty;
      final isSearching = _searchController.text.isNotEmpty;

      // Wrap in ListView to enable pull-to-refresh even when empty
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(50),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      hasNoCapsules
                          ? Icons.history_rounded
                          : isSearching
                          ? Icons.search_off_rounded
                          : Icons.inbox_rounded,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hasNoCapsules
                        ? 'No played capsules yet'
                        : 'No capsules found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      hasNoCapsules
                          ? 'Capsules you\'ve listened to will appear here'
                          : isSearching
                          ? 'Try adjusting your search or clear filters'
                          : 'No results match your search',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isSearching)
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 20),
                      label: const Text('Clear Search'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  if (hasNoCapsules) ...[
                    Text(
                      'Pull down to refresh',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
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
    // Navigate to audio player screen
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(capsule: capsule),
        ),
      );

      // Reload capsules when returning
      _loadCapsules();
    }
  }

  void _handleShare(VoiceCapsule capsule) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('📤 Sharing: ${capsule.title}')));
  }

  void _handleRename(VoiceCapsule capsule) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('✏️ Renaming: ${capsule.title}')));
  }

  void _handleDelete(VoiceCapsule capsule) async {
    // Cancel scheduled notifications (in case it wasn't played)
    await NotificationService().cancelCapsuleNotification(capsule.id);

    // Delete from database
    await CapsuleDatabase.deleteCapsule(capsule.id);
    await _loadCapsules();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Deleted: ${capsule.title}'),
          backgroundColor: Colors.red.shade400,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              // Restore to database
              await CapsuleDatabase.addCapsule(capsule);
              // Reschedule notifications if capsule not played yet
              if (!capsule.hasBeenOpened) {
                await NotificationService().scheduleCapsuleUnlockNotification(
                  capsule,
                );
                await NotificationService().scheduleUnlockReminder(capsule);
              }
              await _loadCapsules();
            },
          ),
        ),
      );
    }
  }
}
