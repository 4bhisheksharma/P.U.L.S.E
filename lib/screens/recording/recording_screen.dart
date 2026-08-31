import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  static const int _waveformBars = 42;
  final List<double> _amplitudes = List<double>.filled(
    _waveformBars,
    0.0,
    growable: true,
  );

  static const int maxDuration = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    // Default preset: tomorrow at the same hour
    final now = DateTime.now();
    _unlockDate = now.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _titleController.dispose();
    _descriptionController.dispose();

    // If user left without saving, clean up temporary audio file
    if (!_isSaving && _audioPath != null) {
      final path = _audioPath!;
      Future.microtask(() => CapsuleDatabase.deleteAudioFileAt(path));
    }

    super.dispose();
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
          if (!mounted || _isPaused) return;
          setState(() {
            _amplitudes.removeAt(0);
            _amplitudes.add(_normalizeAmplitude(amp.current));
          });
        });
  }

  /// Converts a dBFS reading into a 0..1 bar height.
  double _normalizeAmplitude(double db) {
    const minDb = -45.0;
    if (db.isNaN || db.isInfinite) return 0.06;
    final clamped = db.clamp(minDb, 0.0);
    return ((clamped - minDb) / -minDb).clamp(0.06, 1.0);
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
        title: const Text('Microphone Access Needed'),
        content: Text(
          openSettings
              ? 'P.U.L.S.E needs microphone permission to record voice capsules. Please enable it in Settings.'
              : 'Microphone permission was denied. Allow access to start recording.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (openSettings)
            ElevatedButton(
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
    HapticFeedback.heavyImpact();
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
          _hasRecording = false;
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
    HapticFeedback.mediumImpact();
    await _audioRecorder.pause();
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    HapticFeedback.mediumImpact();
    await _audioRecorder.resume();
    _startTimer();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = await _audioRecorder.stop();

    if (_recordDuration < 1) {
      _showError('Recording was too short');
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _hasRecording = false;
      });
      if (path != null) await CapsuleDatabase.deleteAudioFileAt(path);
      return;
    }

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
    if (_audioPath == null || !_hasRecording) {
      _showError('Please record your voice message first');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title for your capsule');
      return;
    }

    if (_unlockDate == null) {
      _showError('Please select an unlock date');
      return;
    }

    if (!_unlockDate!.isAfter(DateTime.now())) {
      _showError('Unlock date must be in the future');
      return;
    }

    setState(() => _isSaving = true);

    try {
      int? fileSizeBytes;
      try {
        final file = File(_audioPath!);
        if (await file.exists()) {
          fileSizeBytes = await file.length();
        }
      } catch (_) {}

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
        fileSizeBytes: fileSizeBytes,
      );

      await CapsuleDatabase.addCapsule(capsule);

      // Schedule notification
      final notificationsScheduled =
          await NotificationService().scheduleForCapsule(capsule);

      if (!mounted) return;

      if (!notificationsScheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Capsule saved! Tip: Enable notifications in app settings to receive unlock alerts.',
            ),
            backgroundColor: MyAppTheme.warningColor,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Capsule "${capsule.title}" locked until ${DateFormat.yMMMd().format(capsule.unlockDate)}',
            ),
            backgroundColor: MyAppTheme.successColor,
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
      SnackBar(
        content: Text(message),
        backgroundColor: MyAppTheme.errorColor,
      ),
    );
  }

  Future<void> _selectUnlockDate() async {
    final now = DateTime.now();
    final initial = _unlockDate ?? now.add(const Duration(days: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)), // ~10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: MyAppTheme.primaryColor,
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
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: MyAppTheme.primaryColor,
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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isSaving
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MyAppTheme.primaryColor,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _saveCapsule,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Lock & Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recording Studio Section
              _buildRecordingSection(theme),
              const SizedBox(height: 24),

              // Title input
              _buildTextField(
                controller: _titleController,
                label: 'Capsule Title',
                hint: 'e.g. Note to my future self, Goals for 2027...',
                icon: Icons.title_rounded,
                enabled: !_isRecording,
              ),
              const SizedBox(height: 14),

              // Description input
              _buildTextField(
                controller: _descriptionController,
                label: 'Description / Note (Optional)',
                hint: 'Write context, memories, or why you made this...',
                icon: Icons.notes_rounded,
                maxLines: 2,
                enabled: !_isRecording,
              ),
              const SizedBox(height: 18),

              // Emotion selector
              _buildEmotionSelector(theme),
              const SizedBox(height: 18),

              // Unlock date presets & custom picker
              _buildUnlockDateSection(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: MyAppTheme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isRecording
              ? MyAppTheme.primaryColor.withValues(alpha: 0.6)
              : MyAppTheme.borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Duration display
          Text(
            _formatDuration(_recordDuration),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: _isRecording
                  ? MyAppTheme.primaryColor
                  : MyAppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRecording
                ? (_isPaused ? 'Recording Paused' : 'Listening...')
                : _hasRecording
                ? 'Recording Ready (${_formatDuration(_recordDuration)})'
                : 'Tap microphone to start recording',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _isRecording
                  ? MyAppTheme.primaryColor
                  : MyAppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Live waveform visualization
          if (_isRecording) ...[
            RecordingWaveform(
              amplitudes: _amplitudes,
              color: MyAppTheme.primaryColor,
              isActive: !_isPaused,
              height: 56,
            ),
            const SizedBox(height: 16),
          ],

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Pause/Resume button
                _buildCircleControl(
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? 'Resume' : 'Pause',
                  color: MyAppTheme.warningColor,
                  onTap: _isPaused ? _resumeRecording : _pauseRecording,
                ),
                const SizedBox(width: 24),
                // Stop button
                _buildCircleControl(
                  icon: Icons.stop_rounded,
                  label: 'Done',
                  color: MyAppTheme.errorColor,
                  onTap: _stopRecording,
                  isPrimary: true,
                ),
              ] else if (_hasRecording) ...[
                // Re-record button
                _buildCircleControl(
                  icon: Icons.refresh_rounded,
                  label: 'Re-record',
                  color: MyAppTheme.warningColor,
                  onTap: () async {
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
                ),
              ] else ...[
                // Start recording button
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: MyAppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MyAppTheme.primaryColor.withValues(alpha: 0.38),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (_isRecording) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _recordDuration / maxDuration,
                minHeight: 4,
                backgroundColor: MyAppTheme.surfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  MyAppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleControl({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isPrimary ? color : color.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC0C0D4),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling right now?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC0C0D4),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionTag.values.map((emotion) {
            final isSelected = _selectedEmotion == emotion;
            return FilterChip(
              avatar: Icon(
                emotion.icon,
                size: 16,
                color: isSelected
                    ? MyAppTheme.primaryColor
                    : MyAppTheme.textSecondaryColor,
              ),
              label: Text(emotion.displayName),
              selected: isSelected,
              onSelected: _isRecording
                  ? null
                  : (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedEmotion = selected ? emotion : null;
                      });
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnlockDateSection(ThemeData theme) {
    final presets = [
      {'label': '1 Hour', 'duration': const Duration(hours: 1)},
      {'label': 'Tomorrow', 'duration': const Duration(days: 1)},
      {'label': '1 Week', 'duration': const Duration(days: 7)},
      {'label': '1 Month', 'duration': const Duration(days: 30)},
      {'label': '1 Year', 'duration': const Duration(days: 365)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unlock Date & Time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC0C0D4),
              ),
            ),
            TextButton.icon(
              onPressed: _isRecording ? null : _selectUnlockDate,
              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
              label: const Text('Custom Picker'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Quick presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return OutlinedButton(
              onPressed: _isRecording
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _unlockDate = DateTime.now().add(
                          preset['duration'] as Duration,
                        );
                      });
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(preset['label'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Selected Date Display Card
        InkWell(
          onTap: _isRecording ? null : _selectUnlockDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MyAppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _unlockDate != null
                    ? MyAppTheme.primaryColor.withValues(alpha: 0.5)
                    : MyAppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MyAppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: MyAppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Schedule',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MyAppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _unlockDate != null
                            ? DateFormat.yMMMMEEEEd().add_jm().format(_unlockDate!)
                            : 'Select unlock time',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MyAppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MyAppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
