import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'ui/face_capture_screen.dart';

/// Main library class that provides face capture functionality
class FacelyticalLibrary {
  /// Provides the face capture screen to be used in any app
  ///
  /// [onImageCaptured] Callback function when an image is successfully captured
  /// [onCaptureError] Callback function when an error occurs during capture
  /// [onPermissionDenied] Callback function when camera permission is denied
  /// [onBackPressed] Callback function when back button is pressed
  static Widget faceCaptureView({
    required Function(Uint8List) onImageCaptured,
    required Function(Exception) onCaptureError,
    required VoidCallback onPermissionDenied,
    VoidCallback? onBackPressed,
    Function(bool)? onSupportTapped,
    bool showSupportText = true,
  }) {
    return FaceCaptureScreen(
      onImageCaptured: onImageCaptured,
      onCaptureError: onCaptureError,
      onPermissionDenied: onPermissionDenied,
      onBackPressed: onBackPressed ?? () {},
      onSupportTapped: onSupportTapped ?? (_) {},
      showSupportText: showSupportText,
    );
  }
}
