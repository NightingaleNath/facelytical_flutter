import 'package:flutter/material.dart';

/// A circular capture button that shows a loading indicator when capturing
/// and a lock icon when disabled
class CaptureButton extends StatelessWidget {
  final VoidCallback onCapture;
  final bool enabled;
  final bool isCapturing;

  const CaptureButton({
    super.key,
    required this.onCapture,
    required this.enabled,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Transform.scale(
        scale: enabled ? 1.0 : 0.95,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: enabled ? 8 : 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            padding: const EdgeInsets.all(5),
            child: GestureDetector(
              onTap: enabled && !isCapturing ? onCapture : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      enabled
                          ? Colors.white
                          : Colors.grey.withValues(alpha: .5),
                  border: Border.all(
                    width: 2,
                    color:
                        enabled
                            ? Colors.white
                            : Colors.grey.withValues(alpha: .3),
                  ),
                ),
                child:
                    isCapturing
                        ? const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                        : !enabled
                        ? const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
