import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/home/search_bar_widget.dart';
import 'package:pulse/widgets/home/capsule_card.dart';
import 'package:pulse/screens/recording/recording_screen.dart';
import 'package:pulse/screens/player/audio_player_screen.dart';
import 'package:pulse/utils/test_helpers.dart';

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

    // Load from database and filter out played capsules
    final allCapsules = CapsuleDatabase.getAllCapsules();
    _capsules = allCapsules.where((c) => !c.hasBeenOpened).toList();

    // Sort by unlock date (soonest first)
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
        backgroundColor: Colors.transparent,
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
          // Notification icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleDebugAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'played',
                child: Text('▶️ Played Capsules'),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Text('📊 Show Statistics'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('🔄 Refresh List'),
              ),
            ],
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
              ),
              const SizedBox(height: 24),

              // Recordings list with pull-to-refresh
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
        // Search only unplayed capsules
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

  Future<void> _handleDebugAction(String action) async {
    switch (action) {
      case 'played':
        // Navigate to played capsules screen
        if (mounted) {
          Navigator.pushNamed(context, '/played');
        }
        break;

      case 'stats':
        final stats = TestHelpers.getLockStatistics();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📊 Capsule Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Capsules: ${stats['total']}'),
                  const SizedBox(height: 8),
                  Text('🔒 Locked: ${stats['locked']}'),
                  Text('⏰ Unlockable: ${stats['unlockable']}'),
                  Text('✅ Opened: ${stats['opened']}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        break;

      case 'refresh':
        await _loadCapsules();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Refreshed capsule list'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        break;
    }
  }

  Widget _buildRecordingsList() {
    if (_filteredCapsules.isEmpty) {
      // Show different message based on whether there are any capsules at all
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
                    hasNoCapsules ? Icons.mic : Icons.search_off,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasNoCapsules ? 'No capsules yet' : 'No capsules found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasNoCapsules
                        ? 'Tap + to record your first time capsule'
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
          child: _buildCapsuleCard(capsule),
        );
      },
    );
  }

  Widget _buildCapsuleCard(VoiceCapsule capsule) {
    return CapsuleCard(
      capsule: capsule,
      onTap: () => _handlePlay(capsule),
      onShare: () => _handleShare(capsule),
      onRename: () => _handleRename(capsule),
      onDelete: () => _handleDelete(capsule),
    );
  }

  void _handlePlay(VoiceCapsule capsule) async {
    if (capsule.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 This capsule is still locked!'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    // Mark as opened if it's the first time
    if (!capsule.hasBeenOpened) {
      final updatedCapsule = capsule.copyWith(hasBeenOpened: true);
      await CapsuleDatabase.updateCapsule(updatedCapsule);
    }

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
    if (capsule.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Cannot share a locked capsule'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

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
    await _loadCapsules(); // Reload from database

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🗑️ Deleted: ${capsule.title}',
          style: TextStyle(
            color: MyAppTheme.darkTheme.textTheme.bodyLarge?.color,
          ),
        ),
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

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withAlpha(150),
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

          // Reload capsules if a new one was saved
          if (result == true && mounted) {
            _loadCapsules();
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
