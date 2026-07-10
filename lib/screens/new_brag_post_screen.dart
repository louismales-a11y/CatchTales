import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img_lib;
import '../services/brag_board_service.dart';

/// Screen to create a new brag post with photo.
class NewBragPostScreen extends StatefulWidget {
  const NewBragPostScreen({super.key});

  @override
  State<NewBragPostScreen> createState() => _NewBragPostScreenState();
}

class _NewBragPostScreenState extends State<NewBragPostScreen> {
  final _speciesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();
  XFile? _image;
  bool _uploading = false;

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _locationCtrl.dispose();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    try {
      final img = await BragBoardService.pickImage();
      if (img == null || !mounted) return;

      final bytes = await img.readAsBytes();
      if (!mounted) return;

      final croppedBytes = await _showCropDialog(bytes);
      if (croppedBytes == null || !mounted) return;

      // Compress: resize to max 1024px and encode as JPEG quality 70
      final compressed = _compressImage(croppedBytes);

      // Save compressed bytes to a temp file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/catchtales_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressed);

      setState(() => _image = XFile(tempFile.path));
    } catch (e) {
      debugPrint('NewBragPostScreen._pickAndCropImage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not process photo. Try again.'),
          ),
        );
      }
    }
  }

  /// Compress image: resize to max 1024px, encode as JPEG quality 70.
  Uint8List _compressImage(Uint8List bytes) {
    final decoded = img_lib.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Resize if larger than 1024px on the longest side
    img_lib.Image resized;
    if (decoded.width > 1024 || decoded.height > 1024) {
      final scale = 1024.0 / (decoded.width > decoded.height
          ? decoded.width
          : decoded.height);
      resized = img_lib.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    } else {
      resized = decoded;
    }

    return Uint8List.fromList(img_lib.encodeJpg(resized, quality: 70));
  }

  /// Show a full-screen interactive crop editor.
  Future<Uint8List?> _showCropDialog(Uint8List imageBytes) async {
    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CropScreen(imageBytes: imageBytes),
      ),
    );
    return croppedBytes;
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Select a photo first')),
      );
      return;
    }
    final species = _speciesCtrl.text.trim();
    if (species.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Enter the fish species')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final id = await BragBoardService.instance.createPost(
        photo: _image!,
        species: species,
        description: _locationCtrl.text.trim(),
        moreInfo: _infoCtrl.text.trim().isEmpty ? null : _infoCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Posted! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Failed to post. Try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('NewBragPostScreen._submit error: $e');
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Share Your Catch')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Photo picker
          GestureDetector(
            onTap: _pickAndCropImage,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_image!.path), width: double.infinity, height: 260, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.white38)),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 48, color: Colors.white38),
                        SizedBox(height: 8),
                        Text('Tap to add a photo', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Species
          TextField(
            controller: _speciesCtrl,
            decoration: InputDecoration(
              labelText: 'Fish Species *',
              hintText: 'e.g. Largemouth Bass, Walleye, Pike...',
              prefixIcon: const Icon(Icons.set_meal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Location
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              labelText: 'Location (optional)',
              hintText: 'Where did you catch it?',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // More Info
          TextField(
            controller: _infoCtrl,
            decoration: InputDecoration(
              labelText: 'More Info (optional, shown on detail page)',
              hintText: 'Weight, length, lure, conditions...',
              prefixIcon: const Icon(Icons.info_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _uploading ? null : _submit,
              icon: _uploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(_uploading ? 'Posting...' : '🐟 Post to Brag Board'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Suggest location from photo EXIF or phone GPS.
}

/// Full-screen interactive crop editor using [crop_your_image].
class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const _CropScreen({required this.imageBytes});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _controller = CropController();

  void _crop() {
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Photo'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Could not crop image.'),
              ),
            );
          }
        },
        interactive: true,
        onStatusChanged: (status) {
          debugPrint('Crop status: $status');
        },
        maskColor: Colors.black.withValues(alpha: 0.6),
        baseColor: theme.scaffoldBackgroundColor,
        cornerDotBuilder: (size, edge) => const DotControl(color: Color(0xFF76FF03)),
      ),
    );
  }
}
