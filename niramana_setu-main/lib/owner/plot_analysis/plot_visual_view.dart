import 'package:flutter/material.dart';

class PlotVisualView extends StatelessWidget {
  final double plotLength;
  final double plotWidth;
  final Map<String, double> setbacks; // front, back, left, right

  const PlotVisualView({
    super.key,
    required this.plotLength,
    required this.plotWidth,
    required this.setbacks,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _PlotPainter(
            plotLength: plotLength,
            plotWidth: plotWidth,
            setbacks: setbacks,
          ),
        ),
      ),
    );
  }
}

class _PlotPainter extends CustomPainter {
  final double plotLength;
  final double plotWidth;
  final Map<String, double> setbacks;

  _PlotPainter({
    required this.plotLength,
    required this.plotWidth,
    required this.setbacks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black;

    // Scale logic to fit plot in canvas with padding
    final double padding = 20.0;
    final double availableWidth = size.width - (padding * 2);
    final double availableHeight = size.height - (padding * 2);

    final double scaleX = availableWidth / plotWidth;
    final double scaleY = availableHeight / plotLength;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Center the plot
    final double drawnWidth = plotWidth * scale;
    final double drawnLength = plotLength * scale;
    final double offsetX = (size.width - drawnWidth) / 2;
    final double offsetY = (size.height - drawnLength) / 2;

    // Draw Plot Boundary
    final Rect plotRect = Rect.fromLTWH(offsetX, offsetY, drawnWidth, drawnLength);
    canvas.drawRect(plotRect, paint);

    // Draw Setbacks (Red Zones)
    final double sFront = (setbacks['front'] ?? 0) * scale;
    final double sBack = (setbacks['back'] ?? 0) * scale;
    final double sLeft = (setbacks['left'] ?? 0) * scale;
    final double sRight = (setbacks['right'] ?? 0) * scale;

    final Paint setbackPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.2);

    // Front Setback
    canvas.drawRect(
      Rect.fromLTWH(plotRect.left, plotRect.top, plotRect.width, sFront),
      setbackPaint,
    );
    // Back Setback
    canvas.drawRect(
      Rect.fromLTWH(plotRect.left, plotRect.bottom - sBack, plotRect.width, sBack),
      setbackPaint,
    );
    // Left Setback (between front and back)
    canvas.drawRect(
      Rect.fromLTWH(plotRect.left, plotRect.top + sFront, sLeft, plotRect.height - sFront - sBack),
      setbackPaint,
    );
    // Right Setback
    canvas.drawRect(
      Rect.fromLTWH(plotRect.right - sRight, plotRect.top + sFront, sRight, plotRect.height - sFront - sBack),
      setbackPaint,
    );

    // Draw Buildable Area (Green Zone)
    final Paint buildablePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green.withOpacity(0.2);

    final Rect buildableRect = Rect.fromLTWH(
      plotRect.left + sLeft,
      plotRect.top + sFront,
      plotRect.width - sLeft - sRight,
      plotRect.height - sFront - sBack,
    );

    canvas.drawRect(buildableRect, buildablePaint);
    
    // Draw Buildable Area Border
    final Paint buildableBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.green.shade700;
      
    canvas.drawRect(buildableRect, buildableBorderPaint);

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    _drawLabel(canvas, textPainter, "FRONT", plotRect.topCenter + const Offset(0, -15));
    _drawLabel(canvas, textPainter, "BACK", plotRect.bottomCenter + const Offset(0, 5));
    
    // Dimensions
    _drawLabel(canvas, textPainter, "${plotWidth.toStringAsFixed(1)}m", plotRect.topCenter + const Offset(0, 5));
    _drawLabel(canvas, textPainter, "${plotLength.toStringAsFixed(1)}m", plotRect.centerLeft + const Offset(-5, 0), rotate: -1.5708);
  }

  void _drawLabel(Canvas canvas, TextPainter tp, String text, Offset position, {double rotate = 0}) {
    tp.text = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
    );
    tp.layout();
    
    if (rotate != 0) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotate);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
