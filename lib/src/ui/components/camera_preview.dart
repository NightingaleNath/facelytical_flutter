import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../camera/camera_manager.dart';

/// Displays camera preview and handles lifecycle events
class CameraPreviewWidget extends StatefulWidget {
  final CameraManager cameraManager;
  final Function(Exception) onError;

  const CameraPreviewWidget({
    super.key,
    required this.cameraManager,
    required this.onError,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cameraManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive) {
      // App is inactive, release camera
      widget.cameraManager.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, reinitialize camera
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      await widget.cameraManager.startCamera(onError: widget.onError);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      widget.onError(e as Exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraPreview = widget.cameraManager.getCameraPreview();

    // If we have a valid camera controller
    if (cameraPreview is CameraPreview) {
      final controller = cameraPreview.controller;
      final isFrontCamera =
          controller.description.lensDirection == CameraLensDirection.front;

      // Basic square preview container
      final container = Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: cameraPreview,
      );

      // Apply mirror effect for front camera
      return isFrontCamera
          ? Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Transform.scale(
              scaleX: -1.0, // Horizontal flip for front camera
              child: cameraPreview,
            ),
          )
          : container;
    } else {
      // Return the original preview if it's not a CameraPreview (e.g. loading indicator)
      return cameraPreview;
    }
  }
}
