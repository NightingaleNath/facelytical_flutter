import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'face_detection_service.dart';

/// Manages camera operations including setup, face detection, and image capture
class CameraManager {
  static const String _tag = "CameraManager";

  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  // Face detection
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  bool _isFaceDetectionPaused = false;

  // Face detection state
  final ValueNotifier<bool> isFaceDetected = ValueNotifier<bool>(false);

  // Store current face bounds
  Rect? currentFaceBounds;

  // Initialize flag
  bool _isInitialized = false;

  /// Initialize the camera
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw CameraException('no_cameras', 'No cameras available on device.');
      }

      // Initialize face detection service
      await _faceDetectionService.initialize();

      _isInitialized = true;
    } catch (e) {
      debugPrint("$_tag Failed to initialize: $e");
      rethrow;
    }
  }

  /// Start the camera with specified resolution preset
  Future<void> startCamera({
    ResolutionPreset resolutionPreset = ResolutionPreset.medium,
    required Function(Exception) onError,
  }) async {
    if (!_isInitialized) {
      await initialize().catchError((e) => onError(e as Exception));
    }

    try {
      // Find front camera
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      // Create camera controller
      _cameraController = CameraController(
        frontCamera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize the controller
      await _cameraController!.initialize();

      // Lock orientation to portrait
      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      // Start image stream for face detection
      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("$_tag Error starting camera: $e");
      onError(e as Exception);
    }
  }

  /// Process camera images for face detection
  void _processCameraImage(CameraImage image) {
    if (_isFaceDetectionPaused) return;

    _faceDetectionService.processImage(
      image,
      _cameraController!.description.sensorOrientation,
      _cameraController!.description.lensDirection,
      (faceDetected, faceBounds) {
        isFaceDetected.value = faceDetected;
        currentFaceBounds = faceBounds;
      },
    );
  }

  /// Temporarily pause face detection
  void pauseFaceDetection() {
    _isFaceDetectionPaused = true;
    debugPrint("$_tag Face detection paused");
  }

  /// Resume face detection after it was paused
  void resumeFaceDetection() {
    _isFaceDetectionPaused = false;
    debugPrint("$_tag Face detection resumed");
  }

  /// Capture an image and return it as bytes
  Future<void> captureImage({
    required Function(Uint8List) onImageCaptured,
    required Function(Exception) onError,
  }) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      onError(Exception("Camera not initialized"));
      return;
    }

    try {
      // Pause face detection during capture
      pauseFaceDetection();

      // Take picture
      final file = await _cameraController!.takePicture();

      // Get original image bytes
      final bytes = await file.readAsBytes();

      // Check if we have a valid face detection
      if (!isFaceDetected.value || currentFaceBounds == null) {
        // Return the full image anyway instead of error
        onImageCaptured(bytes);
        resumeFaceDetection();
        return;
      }

      // Process the image using the captured file
      final processedImage = await _processImage(bytes);

      onImageCaptured(processedImage);
    } catch (e) {
      debugPrint("$_tag Error capturing image: $e");
      onError(e as Exception);
    } finally {
      // Resume face detection
      resumeFaceDetection();
    }
  }

  /// Process the captured image - SIMPLIFIED VERSION
  Future<Uint8List> _processImage(Uint8List imageBytes) async {
    try {
      // Decode the image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception("Failed to decode image");
      }

      // Apply EXIF orientation correction
      final orientedImage = img.bakeOrientation(originalImage);

      // Flip horizontally for front camera
      img.Image processedImage;
      if (_cameraController!.description.lensDirection ==
          CameraLensDirection.front) {
        processedImage = img.flipHorizontal(orientedImage);
      } else {
        processedImage = orientedImage;
      }

      // Only crop if we have valid face bounds
      if (currentFaceBounds != null &&
          _cameraController!.value.previewSize != null) {
        final previewSize = _cameraController!.value.previewSize!;

        // Simple scaling approach
        final double scaleX = processedImage.width / previewSize.width;
        final double scaleY = processedImage.height / previewSize.height;

        // Get face bounds
        final double scaledLeft = currentFaceBounds!.left * scaleX;
        final double scaledTop = currentFaceBounds!.top * scaleY;
        final double scaledWidth = currentFaceBounds!.width * scaleX;
        final double scaledHeight = currentFaceBounds!.height * scaleY;

        // Add padding - move crop area up
        final double padding = scaledWidth * 0.8; // Large padding

        // Calculate crop area - with significantly more space above face
        int cropLeft = math.max(0, (scaledLeft - padding).round());
        int cropTop = math.max(
          0,
          (scaledTop - padding * 1.5).round(),
        ); // More padding on top
        int cropWidth = math.min(
          (scaledWidth + padding * 2).round(),
          processedImage.width - cropLeft,
        );
        int cropHeight = math.min(
          (scaledHeight + padding * 2).round(),
          processedImage.height - cropTop,
        );

        // Ensure square aspect ratio
        int size = math.min(cropWidth, cropHeight);

        // Recenter if needed
        if (cropWidth > size) {
          cropLeft += (cropWidth - size) ~/ 2;
        }
        if (cropHeight > size) {
          cropTop += (cropHeight - size) ~/ 2;
        }

        // Crop the image if all dimensions are valid
        if (size > 0 &&
            cropLeft >= 0 &&
            cropTop >= 0 &&
            cropLeft + size <= processedImage.width &&
            cropTop + size <= processedImage.height) {
          processedImage = img.copyCrop(
            processedImage,
            x: cropLeft,
            y: cropTop,
            width: size,
            height: size,
          );
        }
      }

      // Encode to JPEG
      return Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));
    } catch (e) {
      debugPrint("$_tag Error processing image: $e");
      // Return the original image if processing fails
      return imageBytes;
    }
  }

  /// Release camera resources
  Future<void> dispose() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
        _cameraController = null;
      }

      await _faceDetectionService.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint("$_tag Error disposing camera: $e");
    }
  }

  /// Get the camera preview widget
  Widget getCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_cameraController!);
  }
}
