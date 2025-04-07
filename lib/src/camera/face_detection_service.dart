import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service responsible for detecting faces in camera frames
class FaceDetectionService {
  static const String _tag = "FaceDetectionService";

  late final FaceDetector _faceDetector;
  bool _isProcessing = false;

  // Keep track of previous detections for stability
  bool _lastDetectionResult = false;
  int _stableFrameCount = 0;

  // Last detected face bounds
  Rect? _lastFaceBounds;

  /// Initialize the face detection service
  Future<void> initialize() async {
    // Configure for accuracy and better face detection
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableTracking: true,
      enableLandmarks: true, // Enable landmarks for better face positioning
      minFaceSize: 0.1, // Smaller value to detect faces more easily
    );

    _faceDetector = FaceDetector(options: options);
  }

  /// Process a camera image to detect faces
  Future<void> processImage(
    CameraImage cameraImage,
    int rotation,
    CameraLensDirection cameraLensDirection,
    Function(bool, Rect?) onFaceDetected,
  ) async {
    // Skip processing if already analyzing an image
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Create InputImage from camera image
      final inputImage = _convertCameraImageToInputImage(cameraImage, rotation);

      if (inputImage == null) {
        onFaceDetected(false, null);
        _isProcessing = false;
        return;
      }

      // Process the image
      final faces = await _faceDetector.processImage(inputImage);

      final bool currentDetection = faces.isNotEmpty;

      // Stability logic - require 2 consecutive frames for state change
      if (currentDetection == _lastDetectionResult) {
        _stableFrameCount++;
      } else {
        _stableFrameCount = 0;
      }

      _lastDetectionResult = currentDetection;

      // Only report detection change after consistent frames
      final bool stableDetection =
          _stableFrameCount >= 2
              ? currentDetection
              : (currentDetection && _lastDetectionResult);

      // Get face bounds
      Rect? faceBounds;
      if (stableDetection && faces.isNotEmpty) {
        // Find the best face - most centered and with proper landmarks if possible
        final bestFace = _getBestFaceWithLandmarks(
          faces,
          inputImage.metadata!.size,
        );

        if (bestFace != null) {
          // Get the original bounding box
          final boundingBox = bestFace.boundingBox;

          // Apply proper mirroring for front camera
          final adjustedBoundingBox =
              cameraLensDirection == CameraLensDirection.front
                  ? Rect.fromLTRB(
                    inputImage.metadata!.size.width - boundingBox.right,
                    boundingBox.top,
                    inputImage.metadata!.size.width - boundingBox.left,
                    boundingBox.bottom,
                  )
                  : boundingBox;

          // Add EXTRA padding for head and sides to ensure full face is captured
          // This is critical to avoid the "half face" issue
          final double widthPadding =
              adjustedBoundingBox.width * 0.5; // 50% more on each side
          final double heightPadding =
              adjustedBoundingBox.height * 0.7; // 70% more on top/bottom

          // Create face bounds with extra padding - add more to the top
          // This specifically addresses your issue of only seeing the bottom portion of the face
          faceBounds = Rect.fromLTRB(
            adjustedBoundingBox.left - widthPadding,
            adjustedBoundingBox.top -
                heightPadding * 0.7, // Add more padding at the top
            adjustedBoundingBox.right + widthPadding,
            adjustedBoundingBox.bottom +
                heightPadding * 0.3, // Less padding at the bottom
          );

          // Save the last successful face bounds
          _lastFaceBounds = faceBounds;
        }
      } else if (!stableDetection && _lastFaceBounds != null) {
        // Use last face bounds for stability
        faceBounds = _lastFaceBounds;
      }

      // Pass face detection status and bounds
      onFaceDetected(stableDetection, faceBounds);
    } catch (e) {
      debugPrint("$_tag Face detection failed: $e");
      onFaceDetected(false, null);
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage image, int rotation) {
    try {
      // For Android
      if (Platform.isAndroid) {
        final bytes = _convertYUV420ToNV21(image);

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _rotationIntToImageRotation(rotation),
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }
      // For iOS
      else if (Platform.isIOS) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _rotationIntToImageRotation(rotation),
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      return null;
    } catch (e) {
      debugPrint("$_tag Error converting image: $e");
      return null;
    }
  }

  /// Convert YUV420 to NV21 format for Android
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel!;

    final nv21 = Uint8List(width * height * 3 ~/ 2);

    // Copy Y plane
    int yIndex = 0;
    for (int y = 0; y < height; y++) {
      final yLineStart = y * yRowStride;
      for (int x = 0; x < width; x++) {
        nv21[yIndex++] = yPlane.bytes[yLineStart + x];
      }
    }

    // Copy U and V planes interleaved
    int uvIndex = width * height;
    for (int y = 0; y < height ~/ 2; y++) {
      final uvLineStart = y * uvRowStride;
      for (int x = 0; x < width ~/ 2; x++) {
        final uvPixelIndex = uvLineStart + x * uvPixelStride;
        nv21[uvIndex++] = vPlane.bytes[uvPixelIndex];
        nv21[uvIndex++] = uPlane.bytes[uvPixelIndex];
      }
    }

    return nv21;
  }

  /// Get the best face with proper landmarks
  Face? _getBestFaceWithLandmarks(List<Face> faces, Size imageSize) {
    if (faces.isEmpty) return null;
    if (faces.length == 1) return faces.first;

    // Find faces with good landmarks (eyes, nose, etc.)
    final facesWithLandmarks =
        faces
            .where(
              (face) =>
                  face.landmarks[FaceLandmarkType.leftEye] != null &&
                  face.landmarks[FaceLandmarkType.rightEye] != null,
            )
            .toList();

    // If we have faces with landmarks, use those
    final candidateFaces =
        facesWithLandmarks.isNotEmpty ? facesWithLandmarks : faces;

    // Find the center of the image
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;

    // Find the face closest to center with the largest size
    Face bestFace = candidateFaces.first;
    double bestScore = 0;

    for (final face in candidateFaces) {
      final faceCenter = Offset(
        face.boundingBox.left + face.boundingBox.width / 2,
        face.boundingBox.top + face.boundingBox.height / 2,
      );

      // Calculate distance from center (normalized by image size)
      final distanceFromCenter =
          ((faceCenter.dx - centerX) / imageSize.width).abs() +
          ((faceCenter.dy - centerY) / imageSize.height).abs();

      // Calculate size ratio (larger is better)
      final sizeRatio =
          (face.boundingBox.width * face.boundingBox.height) /
          (imageSize.width * imageSize.height);

      // Weighted score - prioritize size and center position
      // This helps find a properly centered face
      final score = sizeRatio * (1.0 - distanceFromCenter);

      if (score > bestScore) {
        bestScore = score;
        bestFace = face;
      }
    }

    return bestFace;
  }

  /// Convert rotation degrees to InputImageRotation
  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Dispose the face detector
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
