import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
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
              ),
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

  Widget _buildCapsulesList() {
    if (_filteredCapsules.isEmpty) {
      final hasNoCapsules = _capsules.isEmpty && _searchController.text.isEmpty;

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
                  Icon(
                    hasNoCapsules ? Icons.history : Icons.search_off,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasNoCapsules
                        ? 'No played capsules yet'
                        : 'No capsules found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasNoCapsules
                        ? 'Capsules you\'ve listened to will appear here'
                        : 'Try a different search term',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (hasNoCapsules)
                    Text(
                      'Pull down to refresh',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
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
              await _loadCapsules();
            },
          ),
        ),
      );
    }
  }
}
