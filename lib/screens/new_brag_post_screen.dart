import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/brag_board_service.dart';
import '../widgets/water_background.dart';

/// Screen to create a new brag post with photo.
class NewBragPostScreen extends StatefulWidget {
  const NewBragPostScreen({super.key});

  @override
  State<NewBragPostScreen> createState() => _NewBragPostScreenState();
}

class _NewBragPostScreenState extends State<NewBragPostScreen> {
  final _speciesCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _uploading = false;

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _descCtrl.dispose();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await BragBoardService.pickImage();
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _image = img;
        _imageBytes = bytes;
      });
    }
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
    final bytes = _imageBytes ?? await _image!.readAsBytes();
    final id = await BragBoardService.instance.createPost(
      imageBytes: bytes,
      species: species,
      description: _descCtrl.text.trim(),
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
            onTap: _pickImage,
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
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, width: double.infinity, height: 260, fit: BoxFit.cover)
                          : Image.file(File(_image!.path), width: double.infinity, height: 260, fit: BoxFit.cover),
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

          // Description
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Tell us about the catch...',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // More Info
          TextField(
            controller: _infoCtrl,
            decoration: InputDecoration(
              labelText: 'More Info (optional, shown on detail page)',
              hintText: 'Weight, length, lure, location, conditions...',
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
}
