import 'package:flutter/material.dart';

/// The face frame overlay displayed on top of camera preview
class FaceFrame extends StatefulWidget {
  final bool isFaceDetected;

  const FaceFrame({super.key, required this.isFaceDetected});

  @override
  State<FaceFrame> createState() => _FaceFrameState();
}

class _FaceFrameState extends State<FaceFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _colorAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Animation for smoother color transition
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add a subtle pulse animation for better feedback
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Update animation based on face detection state
    _updateAnimation();
  }

  @override
  void didUpdateWidget(FaceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFaceDetected != widget.isFaceDetected) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isFaceDetected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isFaceDetected ? _pulseAnimation.value : 1.0,
          child: CustomPaint(
            size: Size.infinite,
            painter: FaceFramePainter(
              animationValue: _colorAnimation.value,
              isFaceDetected: widget.isFaceDetected,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing the face frame
class FaceFramePainter extends CustomPainter {
  final double animationValue;
  final bool isFaceDetected;

  FaceFramePainter({
    required this.animationValue,
    required this.isFaceDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.5;
    final cornerLength = 35.0;

    // Make frame slightly smaller for better visibility
    final padding = 40.0; // Increased for better centering
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - (padding * 2),
      size.height - (padding * 2),
    );

    // Interpolate color between white and green based on animation value
    final frameColor =
        Color.lerp(
          Colors.white.withValues(alpha: .8),
          Colors.green,
          animationValue,
        )!;

    final paint =
        Paint()
          ..color = frameColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Draw the top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      paint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );

    // Draw the top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Draw the bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );

    // Draw the bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(FaceFramePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isFaceDetected != isFaceDetected;
  }
}
