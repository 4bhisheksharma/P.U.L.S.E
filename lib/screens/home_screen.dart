import 'package:flutter/material.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/home/app_header.dart';
import 'package:pulse/widgets/home/search_bar_widget.dart';
import 'package:pulse/widgets/home/recording_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> recordings = [
    {'title': 'Recordings 1', 'date': '2 days ago | 2 days to go'},
    {'title': 'recording 2', 'date': '5 days ago | 3 days to go'},
    {'title': 'Meeting Notes', 'date': '1 week ago | 1 week to go'},
    {'title': 'Voice Memo', 'date': '2 weeks ago | 1 week to go'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(),
              const SizedBox(height: 24),

              //FIXME: yo baki chha UI fix garna
              SearchBarWidget(
                controller: _searchController,
                onChanged: (value) {
                  // Handle search
                },
              ),
              const SizedBox(height: 24),

              // Recordings list
              Expanded(child: _buildRecordingsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildRecordingsList() {
    return ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RecordingCard(
            title: recordings[index]['title']!,
            date: recordings[index]['date']!,
            onPlay: () {
              _handlePlay(recordings[index]['title']!);
            },
            onShare: () {
              _handleShare(recordings[index]['title']!);
            },
            onRename: () {
              _handleRename(recordings[index]['title']!);
            },
            onDelete: () {
              _handleDelete(recordings[index]['title']!);
            },
          ),
        );
      },
    );
  }

  void _handlePlay(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Playing: $title')));
  }

  void _handleShare(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sharing: $title')));
  }

  void _handleRename(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Renaming: $title')));
  }

  void _handleDelete(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted: $title',
          style: TextStyle(
            color: MyAppTheme.darkTheme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.red.shade400,
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
        onPressed: () {
          // Handle recording action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start recording...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
