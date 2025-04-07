import 'package:flutter/material.dart';
import '../../models/tutorial_step.dart';

class FaceWalkthroughDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const FaceWalkthroughDialog({super.key, required this.onDismiss});

  @override
  State<FaceWalkthroughDialog> createState() => _FaceWalkthroughDialogState();
}

class _FaceWalkthroughDialogState extends State<FaceWalkthroughDialog> {
  int _currentStep = 0;

  // Tutorial content for face capture
  final List<TutorialStep> _tutorials = const [
    TutorialStep(
      title: "Position Your Face Properly",
      description:
          "Center your face within the frame and make sure your entire face is visible. Keep a neutral expression for best results.",
      icon: Icons.face,
    ),
    TutorialStep(
      title: "Good Lighting is Essential",
      description:
          "Ensure your face is well lit with even lighting. Avoid harsh shadows or bright light directly behind you that can cause silhouetting.",
      icon: Icons.wb_sunny,
    ),
    TutorialStep(
      title: "Remove Obstructions",
      description:
          "Remove sunglasses, hats, or other items that might obscure facial features. Ensure there are no objects partially blocking your face.",
      icon: Icons.image,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 48),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Face illustration
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4BB6EF),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _tutorials[_currentStep].icon,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ),
            ),

            // Close button
            GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            // Tutorial title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _tutorials[_currentStep].title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Tutorial description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _tutorials[_currentStep].description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            // Navigation dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_tutorials.length, (index) {
                final selected = index == _currentStep;
                return GestureDetector(
                  onTap: () => setState(() => _currentStep = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: selected ? 10 : 6,
                    height: selected ? 10 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF4BB6EF) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        widget.onDismiss();
                      }
                    },
                    child: Text(
                      _currentStep == 0 ? "SKIP" : "BACK",
                      style: TextStyle(
                        color:
                            _currentStep > 0
                                ? const Color(0xFF4BB6EF)
                                : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_currentStep < _tutorials.length - 1) {
                        setState(() => _currentStep++);
                      } else {
                        widget.onDismiss();
                      }
                    },
                    child: Text(
                      _currentStep < _tutorials.length - 1 ? "NEXT" : "DONE",
                      style: const TextStyle(
                        color: Color(0xFF4BB6EF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
