import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../camera/camera_manager.dart';
import '../utils/instructions.dart';
import '../utils/permissions_handler.dart';
import 'components/camera_preview.dart';
import 'components/capture_button.dart';
import 'components/face_frame.dart';
import 'components/walkthrough_dialog.dart';

/// Main screen for face capture functionality
class FaceCaptureScreen extends StatefulWidget {
  final Function(Uint8List) onImageCaptured;
  final Function(Exception) onCaptureError;
  final VoidCallback onPermissionDenied;
  final VoidCallback onBackPressed;
  final Function(bool) onSupportTapped;
  final bool showSupportText;

  const FaceCaptureScreen({
    super.key,
    required this.onImageCaptured,
    required this.onCaptureError,
    required this.onPermissionDenied,
    required this.onBackPressed,
    required this.onSupportTapped,
    this.showSupportText = true,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  // Camera manager
  late CameraManager _cameraManager;

  // UI states
  bool _isCapturing = false;
  bool _hasPermission = false;
  bool _showWalkthrough = false;

  @override
  void initState() {
    super.initState();
    _cameraManager = CameraManager();
    _checkPermission();
  }

  @override
  void dispose() {
    _cameraManager.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await PermissionsHandler.hasCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });

    if (!hasPermission) {
      await PermissionsHandler.requestCameraPermission(
        onPermissionGranted: () {
          setState(() {
            _hasPermission = true;
          });
        },
        onPermissionDenied: () {
          setState(() {
            _hasPermission = false;
          });
          widget.onPermissionDenied();
        },
      );
    }
  }

  void _captureImage() {
    setState(() {
      _isCapturing = true;
    });

    // Pause face detection during capture
    _cameraManager.pauseFaceDetection();

    _cameraManager.captureImage(
      onImageCaptured: (imageBytes) {
        setState(() {
          _isCapturing = false;
        });

        // Resume face detection
        _cameraManager.resumeFaceDetection();

        // Stop camera before returning to third-party app
        _cameraManager.dispose();

        // Pass image to callback
        widget.onImageCaptured(imageBytes);
      },
      onError: (error) {
        setState(() {
          _isCapturing = false;
        });

        // Resume face detection
        _cameraManager.resumeFaceDetection();

        // Check if this is a "No face detected" error
        if (error.toString().contains("No face detected")) {
          // Show snackbar instead of passing error back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No face detected. Please keep your face in the frame.",
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Handle other errors normally
          setState(() {});
          widget.onCaptureError(error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final previewSizePercent = screenSize.height < 600 ? 0.75 : 0.85;
    final previewSize = screenSize.width * previewSizePercent;

    // Define background color
    const backgroundColor = Color(0xFF0F172A);

    // Show walkthrough dialog if requested
    if (_showWalkthrough) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => FaceWalkthroughDialog(
                onDismiss: () {
                  setState(() {
                    _showWalkthrough = false;
                    Navigator.of(context).pop();
                  });
                },
              ),
        );
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundColor, backgroundColor.withValues(alpha: .8)],
            ),
          ),
          child: CameraPermissionHandler(
            onPermissionGranted: () {
              setState(() {
                _hasPermission = true;
              });
            },
            onPermissionDenied: () {
              setState(() {
                _hasPermission = false;
              });
              widget.onPermissionDenied();
            },
            child:
                _hasPermission
                    ? Column(
                      children: [
                        const SizedBox(height: 20),

                        // Camera preview area
                        Expanded(
                          child: Center(
                            child: Container(
                              width: previewSize,
                              height: previewSize,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color:
                                      _cameraManager.isFaceDetected.value
                                          ? Colors.green
                                          : Colors.white,
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Camera preview
                                  CameraPreviewWidget(
                                    cameraManager: _cameraManager,
                                    onError: (error) {
                                      setState(() {});
                                      widget.onCaptureError(error);
                                    },
                                  ),

                                  // Face frame overlay
                                  ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _cameraManager.isFaceDetected,
                                    builder: (context, isFaceDetected, _) {
                                      return FaceFrame(
                                        isFaceDetected: isFaceDetected,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom section with controls and text
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                backgroundColor.withValues(alpha: .0),
                                backgroundColor.withValues(alpha: .85),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Instruction text
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable:
                                      _cameraManager.isFaceDetected,
                                  builder: (context, isFaceDetected, _) {
                                    final instructionText =
                                        _isCapturing
                                            ? Instructions.capturing
                                            : isFaceDetected
                                            ? Instructions.faceDetected
                                            : Instructions.positionFace;

                                    return Text(
                                      instructionText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  },
                                ),
                              ),

                              // Control buttons row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Close button (left)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 20),
                                      child: GestureDetector(
                                        onTap: () {
                                          _cameraManager.dispose();
                                          widget.onBackPressed();
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: .8,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.25,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Capture button (center)
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          _cameraManager.isFaceDetected,
                                      builder: (context, isFaceDetected, _) {
                                        return CaptureButton(
                                          onCapture: _captureImage,
                                          enabled:
                                              isFaceDetected && !_isCapturing,
                                          isCapturing: _isCapturing,
                                        );
                                      },
                                    ),

                                    // Help button (right)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showWalkthrough = true;
                                          });
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.25,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.question_mark,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Support text button (conditionally shown)
                              if (widget.showSupportText)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _cameraManager.dispose();
                                      widget.onSupportTapped(true);
                                    },
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: const TextSpan(
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                "Verification challenges?\n",
                                          ),
                                          TextSpan(
                                            text: "Contact Support",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    )
                    : _buildPermissionDeniedScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Camera Permission Required",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "This app needs camera permission to detect faces and take photos.",
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _checkPermission,
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }
}
