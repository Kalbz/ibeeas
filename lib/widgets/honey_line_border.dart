import 'package:flutter/material.dart';

class HoneyLineBorderModal extends StatefulWidget {
  final double width;
  final double height;
  final double borderThickness;
  final Widget child; // Add the child parameter

  HoneyLineBorderModal({
    required this.width,
    required this.height,
    required this.borderThickness,
    required this.child, // Add this line to accept a child widget
  });

  @override
  _HoneyLineBorderModalState createState() => _HoneyLineBorderModalState();
}

class _HoneyLineBorderModalState extends State<HoneyLineBorderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Repeat the animation indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Honey border layer using CustomPainter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: HoneyLinePainter(
                    borderThickness: widget.borderThickness,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
          // Main Modal Content
          Padding(
            padding: EdgeInsets.all(widget.borderThickness),
            child: widget.child, // Use the passed child widget here
          ),
        ],
      ),
    );
  }
}

class HoneyLinePainter extends CustomPainter {
  final double borderThickness;
  final double animationValue;

  HoneyLinePainter({required this.borderThickness, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Main honey paint with gradient
    final gradient = LinearGradient(
      colors: [Colors.yellow.shade100, Colors.yellow.shade700],
      stops: [0.0, 1.0],
    );

    final honeyPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness
      ..strokeCap = StrokeCap.round;

    // Highlight paint for glossy effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness / 4
      ..strokeCap = StrokeCap.round;

    // Create a rectangular path around the edges
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          borderThickness / 2,
          borderThickness / 2,
          size.width - borderThickness,
          size.height - borderThickness,
        ),
        Radius.circular(20),
      ));

    // Calculate the length of the entire path
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;

    // Determine the position for the "running" effect
    final start = (animationValue * pathLength) % pathLength;
    final end = (start + (pathLength * 0.3)) % pathLength; // Control length of the running line

    // Create a sub-path for the running effect
    final runningPath = Path();
    if (start < end) {
      // Normal case: draw from start to end
      runningPath.addPath(pathMetric.extractPath(start, end), Offset.zero);
    } else {
      // Wrap-around case: draw from start to end of path and then from 0 to end
      runningPath.addPath(pathMetric.extractPath(start, pathLength), Offset.zero);
      runningPath.addPath(pathMetric.extractPath(0, end), Offset.zero);
    }

    // Draw the running path with the main honey color
    canvas.drawPath(runningPath, honeyPaint);

    // Draw the highlight path slightly offset inside the main path
    final highlightPath = Path();
    if (start < end) {
      // Normal case: draw from start to end
      highlightPath.addPath(pathMetric.extractPath(start, end), Offset.zero);
    } else {
      // Wrap-around case: draw from start to end of path and then from 0 to end
      highlightPath.addPath(pathMetric.extractPath(start, pathLength), Offset.zero);
      highlightPath.addPath(pathMetric.extractPath(0, end), Offset.zero);
    }
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
