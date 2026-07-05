import 'dart:io';
import 'package:flutter/material.dart';
import '../services/help_text.dart';
import '../services/pro_service.dart';
import '../services/translation_service.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tackle_item.dart';
import '../data/tackle_database.dart';
import '../services/tackle_db_service.dart';

/// Screen to add or edit a tackle item — take a photo, pick the type,
/// and it auto-fills target species + tips from the built-in database.
class AddTackleScreen extends StatefulWidget {
  final TackleItem? existingItem;

  const AddTackleScreen({super.key, this.existingItem});

  @override
  State<AddTackleScreen> createState() => _AddTackleScreenState();
}

class _AddTackleScreenState extends State<AddTackleScreen> {
  final _nameCtrl = TextEditingController();
  final _tipsCtrl = TextEditingController();
  String _selectedType = '';
  String? _photoPath;
  List<String> _selectedSpecies = [];
  bool _saving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _selectedType = existing.type;
      _photoPath = existing.photoPath;
      _selectedSpecies = List.from(existing.targetSpecies);
      _tipsCtrl.text = existing.tips;
    }
  }

  /// Grouped tackle types by category.
  Map<String, List<TackleTypeInfo>> get _grouped {
    final map = <String, List<TackleTypeInfo>>{};
    for (final t in tackleTypeDatabase) {
      map.putIfAbsent(t.category, () => []);
      map[t.category]!.add(t);
    }
    return map;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tipsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  void _selectType(TackleTypeInfo info) {
    setState(() {
      _selectedType = info.name;
      _nameCtrl.text = info.name;
      _selectedSpecies = List.from(info.targetSpecies);
      _tipsCtrl.text = info.tips;
    });
    Navigator.pop(context); // close type picker
  }

  void _showTypePicker() {
    final grouped = _grouped;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Select Tackle Type',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          child: Text(entry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              )),
                        ),
                        ...entry.value.map((t) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Text(t.icon, style: const TextStyle(fontSize: 28)),
                                title: Text(t.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(t.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _selectType(t),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                              ),
                            )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating,
              content: Text('Please select a tackle type and name')),
      );
      return;
    }

    setState(() => _saving = true);

    final item = TackleItem(
      id: widget.existingItem?.id,
      name: name,
      type: _selectedType,
      photoPath: _photoPath,
      targetSpecies: _selectedSpecies,
      tips: _tipsCtrl.text.trim(),
    );

    if (_isEditing) {
      await TackleDbService.instance.updateTackleItem(item);
    } else {
      // Check free limit
      final currentCount = await TackleDbService.instance.getTackleItemCount();
      if (!ProService.instance.isPro && currentCount >= ProService.freeTackleLimit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(behavior: SnackBarBehavior.floating,
              content: Text(trp('tackleLimitReached', {'limit': '${ProService.freeTackleLimit}'}))),
          );
          ProService.showUpgradeDialog(context);
        }
        setState(() => _saving = false);
        return;
      }
      await TackleDbService.instance.addTackleItem(item);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating,
              content: Text(_isEditing
            ? '$name updated!'
            : '$name added to tackle box!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Tackle' : 'Add Tackle'),
),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad + 80),
        children: [
          // ── Photo ──
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Tap to take a photo',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Select Type ──
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _showTypePicker,
              icon: const Icon(Icons.search),
              label: Text(
                _selectedType.isNotEmpty
                    ? '$_selectedType  (tap to change)'
                    : 'Select tackle type…',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. White Spinnerbait',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Target Species ──
          if (_selectedSpecies.isNotEmpty) ...[
            const Text('Target Species',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedSpecies.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () {
                      setState(
                          () => _selectedSpecies.remove(s));
                    },
                  )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Tips ──
          TextFormField(
            controller: _tipsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Fishing Tips',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // ── Save ──
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Add to Tackle Box'),
            ),
          ),
          const SizedBox(height: 8),
          helpChip(context, 'add_tackle'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
