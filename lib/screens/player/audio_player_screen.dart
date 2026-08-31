import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/utils/capsule_actions.dart';

class AudioPlayerScreen extends StatefulWidget {
  final VoiceCapsule capsule;

  const AudioPlayerScreen({super.key, required this.capsule});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isPrepared = false;
  bool _markedOpened = false;
  double _playbackRate = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupAudioPlayer();
  }

  Future<void> _markOpenedIfListenedEnough(Duration position) async {
    if (_markedOpened || widget.capsule.hasBeenOpened) return;

    final durationSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds
        : widget.capsule.durationInSeconds;
    final thresholdSeconds = durationSeconds <= 3
        ? 1
        : (durationSeconds * 0.25).ceil().clamp(2, 30);
    if (position.inSeconds < thresholdSeconds) return;

    _markedOpened = true;
    await CapsuleDatabase.updateCapsule(
      widget.capsule.copyWith(hasBeenOpened: true),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    try {
      final file = File(widget.capsule.audioFilePath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Audio file was not found on device';
          _isLoading = false;
        });
        return;
      }

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          final isPlaying = state == PlayerState.playing;
          setState(() => _isPlaying = isPlaying);
          if (isPlaying) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
          }
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
          _pulseController.stop();
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
    HapticFeedback.selectionClick();
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

      await _audioPlayer.setPlaybackRate(_playbackRate);
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

  Future<void> _seekBy(int seconds) async {
    HapticFeedback.selectionClick();
    final newSeconds = (_position.inSeconds + seconds).clamp(
      0,
      _duration.inSeconds,
    );
    await _seek(Duration(seconds: newSeconds));
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showError('Seek error: $e');
    }
  }

  Future<void> _cyclePlaybackRate() async {
    HapticFeedback.selectionClick();
    final rates = [1.0, 1.25, 1.5, 2.0];
    final nextIndex = (rates.indexOf(_playbackRate) + 1) % rates.length;
    final nextRate = rates[nextIndex];

    await _audioPlayer.setPlaybackRate(nextRate);
    setState(() => _playbackRate = nextRate);
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
      appBar: AppBar(
        title: const Text('Time Capsule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share audio',
            onPressed: () => CapsuleActions.shareCapsule(
              context: context,
              capsule: widget.capsule,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Animated Pulse Disc Artwork
              _buildArtDisc(theme, emotion),
              const SizedBox(height: 28),

              // Title and metadata
              Text(
                widget.capsule.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              if (widget.capsule.description != null &&
                  widget.capsule.description!.isNotEmpty) ...[
                Text(
                  widget.capsule.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MyAppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Info Badge (Dates & Emotion)
              _buildInfoBadges(theme, emotion),

              const Spacer(flex: 2),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MyAppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: MyAppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Slider and Timers
                _buildScrubber(theme),
                const SizedBox(height: 16),

                // Controls
                _buildPlayerControls(theme),
              ],

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtDisc(ThemeData theme, EmotionTag? emotion) {
    return ScaleTransition(
      scale: _isPlaying ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyAppTheme.primaryColor.withValues(alpha: 0.35),
              MyAppTheme.cardColor,
            ],
          ),
          border: Border.all(
            color: _isPlaying
                ? MyAppTheme.primaryColor.withValues(alpha: 0.6)
                : MyAppTheme.borderColor,
            width: 2,
          ),
          boxShadow: [
            if (_isPlaying)
              BoxShadow(
                color: MyAppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Center(
          child: Icon(
            emotion?.icon ?? Icons.lock_open_rounded,
            size: 64,
            color: MyAppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadges(ThemeData theme, EmotionTag? emotion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MyAppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyAppTheme.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 15,
            color: MyAppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Recorded ${DateFormat.yMMMd().format(widget.capsule.recordedDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyAppTheme.textSecondaryColor,
            ),
          ),
          if (emotion != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: MyAppTheme.borderColor,
                shape: BoxShape.circle,
              ),
            ),
            Icon(emotion.icon, size: 14, color: MyAppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              emotion.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MyAppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrubber(ThemeData theme) {
    return Column(
      children: [
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _position.inSeconds.toDouble().clamp(0, _sliderMax),
            max: _sliderMax,
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyAppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyAppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Playback speed toggle
        Material(
          color: MyAppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _cyclePlaybackRate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MyAppTheme.borderColor, width: 1),
              ),
              child: Text(
                '${_playbackRate.toStringAsFixed(_playbackRate % 1 == 0 ? 0 : 2)}x',
                style: TextStyle(
                  color: MyAppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Skip -10s
        IconButton(
          onPressed: () => _seekBy(-10),
          icon: const Icon(Icons.replay_10_rounded),
          iconSize: 28,
          color: MyAppTheme.textColor,
          tooltip: 'Rewind 10s',
        ),
        const SizedBox(width: 14),

        // Main Play/Pause Button
        GestureDetector(
          onTap: _playPause,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: MyAppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MyAppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Skip +10s
        IconButton(
          onPressed: () => _seekBy(10),
          icon: const Icon(Icons.forward_10_rounded),
          iconSize: 28,
          color: MyAppTheme.textColor,
          tooltip: 'Forward 10s',
        ),
        const SizedBox(width: 20),

        // Restart from beginning
        IconButton(
          onPressed: () => _seek(Duration.zero),
          icon: const Icon(Icons.restart_alt_rounded),
          iconSize: 24,
          color: MyAppTheme.textSecondaryColor,
          tooltip: 'Restart',
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this Capsule?'),
        content: Text('Permanently delete "${widget.capsule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: MyAppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _audioPlayer.stop();
      await CapsuleDatabase.deleteCapsule(widget.capsule.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
