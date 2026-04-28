import 'package:flutter/material.dart';

/* ============================
   Animated Get Started Button
   ============================ */

class AnimatedGetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedGetStartedButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<AnimatedGetStartedButton> createState() =>
      _AnimatedGetStartedButtonState();
}

class _AnimatedGetStartedButtonState extends State<AnimatedGetStartedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: 280,
        height: 56,
        child: CustomPaint(
          painter: _BorderBeamPainter(progress: _controller),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================
   Border Beam Painter
   ============================ */

class _BorderBeamPainter extends CustomPainter {
  final Animation<double> progress;

  _BorderBeamPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = 28.0;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Base border
    final basePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rrect, basePaint);

    // Path for animation
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;

    final beamLength = metric.length * 0.2;
    final start = metric.length * progress.value;
    final end = start + beamLength;

    Path beamPath;
    if (end < metric.length) {
      beamPath = metric.extractPath(start, end);
    } else {
      beamPath = metric.extractPath(start, metric.length)
        ..addPath(
          metric.extractPath(0, end - metric.length),
          Offset.zero,
        );
    }

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF6A00FF),
          Color(0xFF9B41FF),
          Color(0xFF6A00FF),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(beamPath, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}
