import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';

class AudioPlayerScreen extends StatefulWidget {
  final VoiceCapsule capsule;

  const AudioPlayerScreen({super.key, required this.capsule});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    try {
      // Listen to player state changes
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
            _isLoading = false;
          });
        }
      });

      // Listen to duration changes
      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to position changes
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen to completion
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      // Set audio source
      await _audioPlayer.setSourceDeviceFile(widget.capsule.audioFilePath);
      setState(() => _isLoading = false);

      // Auto-play when opened
      await _playPause();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load audio: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      _showError('Playback error: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
      });
    } catch (e) {
      _showError('Stop error: $e');
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showError('Seek error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emotion = EmotionTag.fromString(widget.capsule.emotionTag);

    return Scaffold(
      appBar: AppBar(title: Text(widget.capsule.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Capsule info card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF2D2D3A),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Emotion emoji
                    if (emotion != null)
                      Text(emotion.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      widget.capsule.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (widget.capsule.description != null)
                      Text(
                        widget.capsule.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),

                    // Recorded date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recorded ${_formatDate(widget.capsule.recordedDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Unlocked date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_open,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unlocked ${_formatDate(widget.capsule.unlockDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade400),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Audio player controls
              if (_errorMessage == null) ...[
                // Progress bar
                Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        max: _duration.inSeconds.toDouble(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                _seek(Duration(seconds: value.toInt()));
                              },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop button
                    IconButton(
                      onPressed: _isLoading ? null : _stop,
                      icon: const Icon(Icons.stop),
                      iconSize: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 32),

                    // Play/Pause button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _playPause,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Replay button (seek to start)
                    IconButton(
                      onPressed: _isLoading ? null : () => _seek(Duration.zero),
                      icon: const Icon(Icons.replay),
                      iconSize: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
