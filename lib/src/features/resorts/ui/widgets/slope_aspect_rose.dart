import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A radial chart showing the distribution of slope aspects.
class SlopeAspectRose extends StatelessWidget {
  const SlopeAspectRose({
    required this.aspectData, super.key,
    this.size = 180,
  });

  /// 8 values mapping to N, NE, E, SE, S, SW, W, NW.
  final List<double> aspectData;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Slope Aspect Rose',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _AspectRosePainter(aspectData: aspectData),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Predominant slope direction',
          style: TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }
}

class _AspectRosePainter extends CustomPainter {
  _AspectRosePainter({required this.aspectData});

  final List<double> aspectData;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(5)
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    // Draw background rings
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius * 0.75, bgPaint);
    canvas.drawCircle(center, radius * 0.5, bgPaint);
    canvas.drawCircle(center, radius * 0.25, bgPaint);

    // Draw cardinal lines
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    
    // Labels
    const labelStyle = TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold);
    _drawText(canvas, 'N', Offset(center.dx, -15), labelStyle);
    _drawText(canvas, 'S', Offset(center.dx, size.height + 5), labelStyle);
    _drawText(canvas, 'E', Offset(size.width + 10, center.dy), labelStyle);
    _drawText(canvas, 'W', Offset(-15, center.dy), labelStyle);

    // Draw data segments
    if (aspectData.length >= 8) {
      final dataPaint = Paint()
        ..style = PaintingStyle.fill;

      // Start from -90 degrees (North)
      const double step = 2 * math.pi / 8;
      double startAngle = -math.pi / 2 - (step / 2);

      for (int i = 0; i < 8; i++) {
        final val = aspectData[i];
        final sliceRadius = radius * (0.2 + (val * 2.5).clamp(0, 0.8));
        
        // Intensity color: North = colder (blue), South = warmer (orange)
        // Indices: 0:N, 1:NE, 2:E, 3:SE, 4:S, 5:SW, 6:W, 7:NW
        Color sliceColor;
        if (i == 0 || i == 1 || i == 7) {
          sliceColor = Colors.blue.withAlpha(200); // Cold (Powder potential)
        } else if (i == 3 || i == 4 || i == 5) {
          sliceColor = Colors.orange.withAlpha(200); // Sunny
        } else {
          sliceColor = Colors.purple.withAlpha(200); // Intermediate
        }

        dataPaint.color = sliceColor;

        final path = Path();
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: sliceRadius),
          startAngle,
          step,
          false,
        );
        path.close();
        
        canvas.drawPath(path, dataPaint);
        
        // Add a highlight stroke
        canvas.drawPath(path, Paint()..color = sliceColor.withAlpha(255)..style = PaintingStyle.stroke..strokeWidth = 1);

        startAngle += step;
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
