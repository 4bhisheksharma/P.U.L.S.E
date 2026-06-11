import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulse/models/models.dart';
import 'package:pulse/services/capsule_database.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:pulse/theme/my_app_theme.dart';
import 'package:pulse/widgets/recording/recording_waveform.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false;
  bool _isSaving = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _audioPath;
  DateTime? _unlockDate;
  EmotionTag? _selectedEmotion;

  StreamSubscription<Amplitude>? _amplitudeSub;
  static const int _waveformBars = 48;
  final List<double> _amplitudes = List<double>.filled(
    _waveformBars,
    0.0,
    growable: true,
  );

  static const int maxDuration = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((amp) {
          if (!mounted || _isPaused) return;
          setState(() {
            _amplitudes.removeAt(0);
            _amplitudes.add(_normalizeAmplitude(amp.current));
          });
        });
  }

  /// Converts a dBFS reading (roughly -45..0) into a 0..1 bar height.
  double _normalizeAmplitude(double db) {
    const minDb = -45.0;
    if (db.isNaN || db.isInfinite) return 0.05;
    final clamped = db.clamp(minDb, 0.0);
    return ((clamped - minDb) / -minDb).clamp(0.05, 1.0);
  }

  void _resetWaveform() {
    for (var i = 0; i < _amplitudes.length; i++) {
      _amplitudes[i] = 0.0;
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    status = await Permission.microphone.request();
    if (status.isGranted) return true;

    if (!mounted) return false;

    final openSettings = status.isPermanentlyDenied;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone access needed'),
        content: Text(
          openSettings
              ? 'PULSE needs microphone access to record voice capsules. '
                  'Enable it in Settings.'
              : 'Microphone permission was denied. Allow access to record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (openSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
    return false;
  }

  Future<void> _startRecording() async {
    try {
      if (await _ensureMicrophonePermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordDuration = 0;
          _audioPath = filePath;
          _resetWaveform();
        });

        _startTimer();
        _startAmplitudeMonitoring();
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    _startTimer();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecording = true;
      _audioPath = path;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordDuration >= maxDuration) {
        _stopRecording();
        _showError('Maximum recording duration reached (5 minutes)');
      } else {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _saveCapsule() async {
    if (_audioPath == null) {
      _showError('No recording found');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_unlockDate == null) {
      _showError('Please select an unlock date');
      return;
    }

    if (_unlockDate!.isBefore(DateTime.now())) {
      _showError('Unlock date must be in the future');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final capsule = VoiceCapsule(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        audioFilePath: _audioPath!,
        recordedDate: DateTime.now(),
        unlockDate: _unlockDate!,
        durationInSeconds: _recordDuration,
        emotionTag: _selectedEmotion?.name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await CapsuleDatabase.addCapsule(capsule);

      final notificationsScheduled =
          await NotificationService().scheduleForCapsule(capsule);

      if (!mounted) return;

      if (!notificationsScheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Capsule saved, but unlock alerts could not be scheduled. '
              'In Settings, allow Notifications and Alarms & reminders for PULSE.',
            ),
            backgroundColor: MyAppTheme.warningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to save capsule: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: MyAppTheme.errorColor),
    );
  }

  Future<void> _selectUnlockDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)), // ~10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              surface: MyAppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: Theme.of(context).colorScheme.primary,
                surface: MyAppTheme.surfaceColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _unlockDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Capsule'),
        actions: [
          if (_hasRecording && !_isRecording)
            TextButton(
              onPressed: _isSaving ? null : _saveCapsule,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Text(
                      'SAVE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recording status
              _buildRecordingSection(theme),
              const SizedBox(height: 32),

              // Title input
              _buildTextField(
                controller: _titleController,
                label: 'Capsule Title',
                hint: 'My Future Self',
                icon: Icons.title,
                enabled: !_isRecording,
              ),
              const SizedBox(height: 16),

              // Description input
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'What is this capsule about?',
                icon: Icons.description,
                maxLines: 3,
                enabled: !_isRecording,
              ),
              const SizedBox(height: 16),

              // Emotion selector
              _buildEmotionSelector(theme),
              const SizedBox(height: 16),

              // Unlock date selector
              _buildUnlockDateSelector(theme),
              const SizedBox(height: 16),

              // Quick presets
              if (!_isRecording) _buildQuickPresets(theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isRecording
              ? theme.colorScheme.primary
              : const Color(0xFF2D2D3A),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Duration display
          Text(
            _formatDuration(_recordDuration),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _isRecording
                  ? theme.colorScheme.primary
                  : theme.textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRecording
                ? _isPaused
                      ? 'Paused'
                      : 'Recording...'
                : _hasRecording
                ? 'Recording Complete'
                : 'Ready to Record',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 20),

          // Live waveform visualization
          if (_isRecording)
            RecordingWaveform(
              amplitudes: _amplitudes,
              color: theme.colorScheme.primary,
              isActive: !_isPaused,
            ),
          if (_isRecording) const SizedBox(height: 20),
          const SizedBox(height: 4),

          // Recording controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Pause/Resume button
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                // Stop button
                _buildControlButton(
                  icon: Icons.stop,
                  onPressed: _stopRecording,
                  color: Colors.red,
                ),
              ] else if (_hasRecording) ...[
                // Re-record button
                _buildControlButton(
                  icon: Icons.refresh,
                  onPressed: () async {
                    final previousPath = _audioPath;
                    setState(() {
                      _hasRecording = false;
                      _recordDuration = 0;
                      _audioPath = null;
                      _resetWaveform();
                    });
                    if (previousPath != null) {
                      await CapsuleDatabase.deleteAudioFileAt(previousPath);
                    }
                  },
                  color: Colors.orange,
                ),
              ] else ...[
                // Start recording button
                _buildControlButton(
                  icon: Icons.fiber_manual_record,
                  onPressed: _startRecording,
                  color: theme.colorScheme.primary,
                  size: 80,
                ),
              ],
            ],
          ),

          // Progress indicator
          if (_isRecording) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _recordDuration / maxDuration,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_recordDuration}s / ${maxDuration}s',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 64,
  }) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEmotionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionTag.values.map((emotion) {
            final isSelected = _selectedEmotion == emotion;
            return FilterChip(
              avatar: Icon(
                emotion.icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
              ),
              label: Text(emotion.displayName),
              selected: isSelected,
              onSelected: _isRecording
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedEmotion = selected ? emotion : null;
                      });
                    },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnlockDateSelector(ThemeData theme) {
    return InkWell(
      onTap: _isRecording ? null : _selectUnlockDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _unlockDate != null
                ? theme.colorScheme.primary
                : const Color(0xFF2D2D3A),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_clock,
              color: _unlockDate != null
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unlock Date', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    _unlockDate != null
                        ? '${_unlockDate!.day}/${_unlockDate!.month}/${_unlockDate!.year} at ${_unlockDate!.hour}:${_unlockDate!.minute.toString().padLeft(2, '0')}'
                        : 'Select when to unlock this capsule',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _unlockDate != null
                          ? theme.textTheme.bodyLarge?.color
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPresets(ThemeData theme) {
    final presets = [
      {'label': '1 Minute', 'duration': const Duration(minutes: 1)},
      {'label': '1 Hour', 'duration': const Duration(hours: 1)},
      {'label': '1 Day', 'duration': const Duration(days: 1)},
      {'label': '1 Week', 'duration': const Duration(days: 7)},
      {'label': '1 Month', 'duration': const Duration(days: 30)},
      {'label': '1 Year', 'duration': const Duration(days: 365)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  _unlockDate = DateTime.now().add(
                    preset['duration'] as Duration,
                  );
                });
              },
              child: Text(preset['label'] as String),
            );
          }).toList(),
        ),
      ],
    );
  }
}
