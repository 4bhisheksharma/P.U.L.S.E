import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';

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
  bool _isPrepared = false;
  bool _markedOpened = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  Future<void> _markOpenedIfListenedEnough(Duration position) async {
    if (_markedOpened || widget.capsule.hasBeenOpened) return;

    final durationSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds
        : widget.capsule.durationInSeconds;
    final thresholdSeconds = durationSeconds <= 3
        ? 1
        : (durationSeconds * 0.25).ceil().clamp(3, 30);
    if (position.inSeconds < thresholdSeconds) return;

    _markedOpened = true;
    await CapsuleDatabase.updateCapsule(
      widget.capsule.copyWith(hasBeenOpened: true),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    try {
      final file = File(widget.capsule.audioFilePath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Audio file not found';
          _isLoading = false;
        });
        return;
      }

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted && duration > Duration.zero) {
          setState(() => _duration = duration);
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() => _position = position);
          _markOpenedIfListenedEnough(position);
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
        _markOpenedIfListenedEnough(_duration);
      });

      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      final source = DeviceFileSource(widget.capsule.audioFilePath);
      await _audioPlayer.play(source);

      final duration = await _audioPlayer.getDuration();
      _isPrepared = true;

      if (mounted) {
        setState(() {
          _duration = duration != null && duration > Duration.zero
              ? duration
              : Duration(seconds: widget.capsule.durationInSeconds);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load audio: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      if (!_isPrepared) {
        await _audioPlayer.setSource(
          DeviceFileSource(widget.capsule.audioFilePath),
        );
        _isPrepared = true;
      }

      if (_position >= _duration && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      }

      await _audioPlayer.resume();
    } catch (e) {
      try {
        await _audioPlayer.play(DeviceFileSource(widget.capsule.audioFilePath));
        _isPrepared = true;
      } catch (playError) {
        _showError('Playback error: $playError');
      }
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
        _isPrepared = false;
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
      SnackBar(content: Text(message), backgroundColor: MyAppTheme.errorColor),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  double get _sliderMax {
    final maxSeconds = _duration.inSeconds.toDouble();
    return maxSeconds > 0 ? maxSeconds : 1;
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    if (emotion != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          emotion.icon,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.capsule.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (widget.capsule.description != null)
                      Text(
                        widget.capsule.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: MyAppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_errorMessage == null) ...[
                Slider(
                  value: _position.inSeconds.toDouble().clamp(0, _sliderMax),
                  max: _sliderMax,
                  onChanged: _isLoading
                      ? null
                      : (value) => _seek(Duration(seconds: value.toInt())),
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
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : _stop,
                      icon: const Icon(Icons.stop),
                      iconSize: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 32),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
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
