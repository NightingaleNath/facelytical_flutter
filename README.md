# Facelytical

![Facelytical](https://img.shields.io/badge/Facelytical-v0.1.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-49A0FC)
![License](https://img.shields.io/badge/License-MIT-green)

A powerful and easy-to-use face detection and capture library for Flutter applications. Facelytical provides a complete solution for real-time face detection, proper face framing, and high-quality image capture.

<p align="center">
  <img src="https://via.placeholder.com/250x500?text=Face+Detection" alt="Face Detection" width="250"/>
  <img src="https://via.placeholder.com/250x500?text=Captured+Image" alt="Captured Image" width="250"/>
</p>

## Features

- ✅ Real-time face detection using Google ML Kit
- ✅ Visual face framing with interactive UI
- ✅ High-quality face image capture
- ✅ Built-in camera permission handling
- ✅ Front-facing camera support with proper mirroring
- ✅ Image processing for optimal face capture
- ✅ Interactive tutorials and guidance for users
- ✅ Easy integration into any Flutter app

## Installation

Add Facelytical to your `pubspec.yaml`:

```yaml
dependencies:
  facelytical:
    git:
      url: https://github.com/yourusername/facelytical.git
      ref: main
```

Or use a specific version:

```yaml
dependencies:
  facelytical:
    git:
      url: https://github.com/yourusername/facelytical.git
      ref: v0.1.0
```

## Requirements

- Flutter SDK: 3.0.0 or higher
- Dart SDK: 2.17.0 or higher
- iOS: 11.0 or higher
- Android: API level 21 (Android 5.0) or higher

## Usage

### Basic Implementation

Integrating Facelytical into your app is simple:

```dart
import 'package:flutter/material.dart';
import 'package:facelytical/facelytical.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? _capturedImage;
  bool _showFaceCapture = false;

  @override
  Widget build(BuildContext context) {
    if (_showFaceCapture) {
      // Show the face capture screen
      return FacelyticalLibrary.faceCaptureView(
        onImageCaptured: (imageBytes) {
          setState(() {
            _capturedImage = imageBytes;
            _showFaceCapture = false;
          });
        },
        onCaptureError: (exception) {
          // Handle errors
          setState(() {
            _showFaceCapture = false;
          });
        },
        onPermissionDenied: () {
          // Handle permission denial
          setState(() {
            _showFaceCapture = false;
          });
        },
        onBackPressed: () {
          // Handle back button press
          setState(() {
            _showFaceCapture = false;
          });
        },
      );
    } else {
      // Show your app's UI
      return Scaffold(
        appBar: AppBar(title: Text("My App")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_capturedImage != null)
                Image.memory(
                  _capturedImage!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFaceCapture = true;
                  });
                },
                child: Text("Capture Face"),
              ),
            ],
          ),
        ),
      );
    }
  }
}
```

### Complete Example

For a full working example, see the [example folder](https://github.com/yourusername/facelytical/example) in the repository.

## Permissions

The library handles camera permissions internally, but you'll need to add the following to your app's manifest files:

### Android

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS

Add to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture your face image</string>
```

## Customization

Facelytical provides a clean, user-friendly UI out of the box, but you can customize aspects of the capture screen by extending the library components.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Developed by [Your Name] and contributors.

For support or questions, reach out to [your-email@example.com].
