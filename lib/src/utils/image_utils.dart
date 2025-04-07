import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Utility functions for image processing
class ImageUtils {
  static const String _tag = "ImageUtils";

  /// More efficient YUV420 to bytes conversion for ML Kit
  static Uint8List yuv420ToBytes(CameraImage image) {
    final yPlane = image.planes[0];
    final yBuffer = yPlane.bytes;

    // Return just Y plane data for ML Kit - it works with grayscale
    return yBuffer;
  }

  /// For more complex processing - full YUV conversion
  static Uint8List yuv420ToRgba(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    final rgba = Uint8List(width * height * 4);

    int index = 0;
    for (int y = 0; y < height; y++) {
      int yIndex = y * yRowStride;
      int uvIndex = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final int yValue = yBuffer[yIndex];

        // Get UV values - note they are sampled at half the resolution
        final int uIndex = uvIndex + ((x ~/ 2) * uvPixelStride);
        final int vIndex = uIndex;

        final int uValue = uBuffer[uIndex];
        final int vValue = vBuffer[vIndex];

        // YUV to RGB conversion
        final int r = (yValue + 1.402 * (vValue - 128)).toInt().clamp(0, 255);
        final int g = (yValue -
                0.344136 * (uValue - 128) -
                0.714136 * (vValue - 128))
            .toInt()
            .clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).toInt().clamp(0, 255);

        rgba[index++] = r;
        rgba[index++] = g;
        rgba[index++] = b;
        rgba[index++] = 255; // Alpha channel

        yIndex++;
      }
    }

    return rgba;
  }

  /// Process the captured XFile to crop to the face region
  static Future<Uint8List> processCapturedImage(
    XFile file,
    Rect? faceBounds,
    bool isFrontCamera,
    Size? previewSize,
  ) async {
    try {
      // Read the image file
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // Fix image orientation based on EXIF data
      img.Image orientedImage = img.bakeOrientation(image);

      // Apply horizontal flip for front camera
      img.Image processedImage;
      if (isFrontCamera) {
        processedImage = img.flipHorizontal(orientedImage);
      } else {
        processedImage = orientedImage;
      }

      // Crop to face bounds if available
      if (faceBounds != null && previewSize != null) {
        // Scale face bounds from preview size to image size
        final scaleX = processedImage.width / previewSize.width;
        final scaleY = processedImage.height / previewSize.height;

        final scaledFaceBounds = Rect.fromLTWH(
          faceBounds.left * scaleX,
          faceBounds.top * scaleY,
          faceBounds.width * scaleX,
          faceBounds.height * scaleY,
        );

        // Ensure bounds are within image dimensions
        final left = scaledFaceBounds.left.toInt().clamp(
          0,
          processedImage.width - 1,
        );
        final top = scaledFaceBounds.top.toInt().clamp(
          0,
          processedImage.height - 1,
        );
        final width = scaledFaceBounds.width.toInt().clamp(
          1,
          processedImage.width - left,
        );
        final height = scaledFaceBounds.height.toInt().clamp(
          1,
          processedImage.height - top,
        );

        processedImage = img.copyCrop(
          processedImage,
          x: left,
          y: top,
          width: width,
          height: height,
        );
      }

      // Convert back to bytes with high quality
      return Uint8List.fromList(img.encodeJpg(processedImage, quality: 95));
    } catch (e) {
      debugPrint("$_tag: Error processing image: $e");
      // Return the original image if processing fails
      return await file.readAsBytes();
    }
  }
}
