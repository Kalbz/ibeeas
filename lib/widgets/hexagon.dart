import 'package:flutter/material.dart';
import 'dart:math' as Math;
import '../models/idea.dart';

class Hexagon extends StatelessWidget {
  final Idea idea;
  final double width;
  final double height;

  Hexagon({required this.idea, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Visibility( // Only render hexagons close to the viewport
      visible: idea.visible,
      child: RepaintBoundary( // Wrap with RepaintBoundary to optimize rendering
        child: CustomPaint(
          size: Size(width, height),
          painter: HexagonPainter(filled: idea.filled),
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Text(
                idea.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final bool filled;

  HexagonPainter({this.filled = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Simplify hexagon drawing to reduce computational cost
    Paint hexagonPaint = Paint()
      ..color = filled ? Colors.orange[800]! : Color(0xFFFFE080)
      ..style = PaintingStyle.fill;

    Paint outlinePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5; // Reduce stroke width to optimize performance

    Path path = Path();
    double width = size.width;
    double height = size.height;
    double sideLength = width / 2;
    double radius = sideLength;
    double centerX = width / 2;
    double centerY = height / 2;

    path.moveTo(centerX + radius, centerY);
    for (int i = 1; i <= 6; i++) {
      path.lineTo(
        centerX + radius * Math.cos(i * Math.pi / 3),
        centerY + radius * Math.sin(i * Math.pi / 3),
      );
    }
    path.close();

    canvas.drawPath(path, hexagonPaint);
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.filled != filled;
  }
}
