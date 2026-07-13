import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/brag_board_service.dart';
import '../services/auth_service.dart';

/// Screen to edit an existing brag post.
class EditBragPostScreen extends StatefulWidget {
  final String postId;
  final String userId;
  final String userName;
  final String initialSpecies;
  final String initialDescription;
  final String? initialMoreInfo;
  final String? initialPhotoData;

  const EditBragPostScreen({
    super.key,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.initialSpecies,
    this.initialDescription = '',
    this.initialMoreInfo,
    this.initialPhotoData,
  });

  @override
  State<EditBragPostScreen> createState() => _EditBragPostScreenState();
}

class _EditBragPostScreenState extends State<EditBragPostScreen> {
  final _speciesCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();
  XFile? _newImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _speciesCtrl.text = widget.initialSpecies;
    _descCtrl.text = widget.initialDescription;
    _infoCtrl.text = widget.initialMoreInfo ?? '';
  }

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _descCtrl.dispose();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (photo != null) setState(() => _newImage = photo);
  }

  Future<void> _save() async {
    final species = _speciesCtrl.text.trim();
    if (species.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Species is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await BragBoardService.instance.updatePost(
      postId: widget.postId,
      userId: widget.userId,
      postUserName: widget.userName,
      species: species != widget.initialSpecies ? species : null,
      description: _descCtrl.text.trim() != widget.initialDescription
          ? _descCtrl.text.trim()
          : null,
      moreInfo: _infoCtrl.text.trim() != (widget.initialMoreInfo ?? '')
          ? (_infoCtrl.text.trim().isEmpty ? null : _infoCtrl.text.trim())
          : null,
      newPhoto: _newImage,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Post updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Failed to update'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Color(0xFF76FF03), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Photo
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: _newImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_newImage!.path), width: double.infinity, height: 220, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 36, color: Colors.white38),
                          SizedBox(height: 6),
                          Text('Tap to change photo (optional)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Species
          TextField(
            controller: _speciesCtrl,
            decoration: InputDecoration(
              labelText: 'Fish Species *',
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
              labelText: 'Description',
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
              labelText: 'More Info (weight, length, lure...)',
              prefixIcon: const Icon(Icons.info_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
