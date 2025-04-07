import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Utility class for handling errors in face capture
class ErrorHandler {
  static const String _tag = "FaceCaptureLibrary";

  /// Handles camera errors and returns a user-friendly error message
  static String handleCameraError(Exception exception) {
    debugPrint("$_tag Camera error: ${exception.toString()}");

    if (exception is CameraException) {
      return "Failed to capture image: ${exception.description}";
    } else if (exception.toString().contains("permission")) {
      return "Camera permission denied";
    } else {
      return "An unexpected error occurred: ${exception.toString()}";
    }
  }
}
