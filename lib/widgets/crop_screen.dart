import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

/// Full-screen interactive square crop editor using [crop_your_image].
/// Used for profile photos. Returns cropped Uint8List or null if cancelled.
class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _controller = CropController();

  void _crop() {
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2137),
        title: const Text('Crop Profile Photo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _crop,
            icon: const Icon(Icons.crop),
            label: const Text('Crop'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF76FF03),
            ),
          ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        onCropped: (result) {
          if (result is CropSuccess) {
            Navigator.pop(context, result.croppedImage);
          } else if (result is CropFailure) {
            debugPrint('Crop error: ${result.cause}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Could not crop image.'),
                ),
              );
            }
          }
        },
        interactive: true,
        maskColor: Colors.black.withValues(alpha: 0.6),
        baseColor: Colors.black,
        cornerDotBuilder: (size, edge) => const DotControl(color: Color(0xFF76FF03)),
        aspectRatio: 1, // Square crop for profile photos
      ),
    );
  }
}
