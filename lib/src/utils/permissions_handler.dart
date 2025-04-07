import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles camera permission requests
class PermissionsHandler {
  /// Requests camera permission and executes appropriate callbacks
  static Future<void> requestCameraPermission({
    required VoidCallback onPermissionGranted,
    required VoidCallback onPermissionDenied,
  }) async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      onPermissionGranted();
    } else {
      onPermissionDenied();
    }
  }

  /// Checks if camera permission is already granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }
}

/// Widget that handles permission checking and requesting
class CameraPermissionHandler extends StatefulWidget {
  final VoidCallback onPermissionGranted;
  final VoidCallback onPermissionDenied;
  final Widget child;

  const CameraPermissionHandler({
    super.key,
    required this.onPermissionGranted,
    required this.onPermissionDenied,
    required this.child,
  });

  @override
  State<CameraPermissionHandler> createState() =>
      _CameraPermissionHandlerState();
}

class _CameraPermissionHandlerState extends State<CameraPermissionHandler> {
  bool _hasCheckedPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!_hasCheckedPermission) {
      _hasCheckedPermission = true;

      if (await PermissionsHandler.hasCameraPermission()) {
        widget.onPermissionGranted();
      } else {
        await PermissionsHandler.requestCameraPermission(
          onPermissionGranted: widget.onPermissionGranted,
          onPermissionDenied: widget.onPermissionDenied,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
