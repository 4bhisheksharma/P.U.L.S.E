import 'package:flutter/material.dart';

/// Animated waveform that visualizes live microphone amplitude while recording.
class RecordingWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;
  final bool isActive;
  final double height;

  const RecordingWaveform({
    super.key,
    required this.amplitudes,
    required this.color,
    this.isActive = true,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          color: color,
          isActive: isActive,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final bool isActive;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final count = amplitudes.length;
    final slot = size.width / count;
    final barWidth = (slot * 0.52).clamp(2.5, 6.0);
    final radius = Radius.circular(barWidth / 2);
    final centerY = size.height / 2;
    final maxBar = size.height * 0.92;

    for (var i = 0; i < count; i++) {
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = (amp * maxBar).clamp(4.0, maxBar);

      // Newer bars towards the right are more vibrant
      final freshness = isActive ? (0.3 + (i / count) * 0.7) : 0.35;
      final paint = Paint()
        ..color = color.withValues(alpha: freshness)
        ..style = PaintingStyle.fill;

      final cx = slot * i + slot / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - barWidth / 2,
          centerY - barHeight / 2,
          barWidth,
          barHeight,
        ),
        radius,
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.isActive != isActive ||
        oldDelegate.color != color;
  }
}
