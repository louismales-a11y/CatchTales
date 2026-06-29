import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/catch.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../services/widget_service.dart';

class AddCatchScreen extends StatefulWidget {
  final Catch? existingCatch;

  const AddCatchScreen({super.key, this.existingCatch});

  @override
  State<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends State<AddCatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _anglerCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _lureCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _caughtAt = DateTime.now();
  File? _photoFile;
  bool _saving = false;
  bool _fetchingLocation = false;
  bool _fetchingWeather = false;

  double? _latitude;
  double? _longitude;
  double? _weatherTemp;
  String? _weatherCondition;

  bool get _isEditing => widget.existingCatch != null;
  bool get _hasLocation => _latitude != null && _longitude != null;
  bool get _hasWeather => _weatherTemp != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingCatch!;
      _anglerCtrl.text = c.angler;
      _speciesCtrl.text = c.species;
      _locationCtrl.text = c.location;
      _lureCtrl.text = c.lure;
      _weightCtrl.text = c.weight?.toStringAsFixed(1) ?? '';
      _lengthCtrl.text = c.length?.toStringAsFixed(1) ?? '';
      _notesCtrl.text = c.notes ?? '';
      _caughtAt = c.caughtAt;
      _latitude = c.latitude;
      _longitude = c.longitude;
      _weatherTemp = c.weatherTemp;
      _weatherCondition = c.weatherCondition;
      if (c.hasPhotos && c.primaryPhoto != null) {
        _photoFile = File(c.primaryPhoto!);
      }
    }
  }

  @override
  void dispose() {
    _anglerCtrl.dispose();
    _speciesCtrl.dispose();
    _locationCtrl.dispose();
    _lureCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services disabled')),
          );
        }
        setState(() => _fetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _fetchingLocation = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _fetchingLocation = false;
        });
        _fetchWeather();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _fetchWeather() async {
    if (!_hasLocation) return;
    setState(() => _fetchingWeather = true);
    final weather =
        await WeatherService.fetchWeather(_latitude!, _longitude!);
    if (mounted && weather != null) {
      setState(() {
        _weatherTemp = weather['temp'] as double;
        _weatherCondition = weather['condition'] as String?;
        _fetchingWeather = false;
      });
    } else {
      if (mounted) setState(() => _fetchingWeather = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _caughtAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_caughtAt),
      );
      if (time != null) {
        setState(() {
          _caughtAt = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
        });
      }
    }
  }

  Future<String?> _savePhoto(File photo) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final catchDir = Directory('${appDir.path}/catch_photos');
      if (!await catchDir.exists()) {
        await catchDir.create(recursive: true);
      }
      final ext = photo.path.split('.').last;
      final fileName = 'catch_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = File('${catchDir.path}/$fileName');
      await photo.copy(savedFile.path);
      return savedFile.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? savedPhotoPath;
      if (_photoFile != null) {
        savedPhotoPath = await _savePhoto(_photoFile!);
      }

      final catchItem = Catch(
        angler: _anglerCtrl.text.trim(),
        species: _speciesCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        lure: _lureCtrl.text.trim(),
        photoPaths: savedPhotoPath != null ? [savedPhotoPath] : null,
        latitude: _latitude,
        longitude: _longitude,
        weatherTemp: _weatherTemp,
        weatherCondition: _weatherCondition,
        weight: _weightCtrl.text.isNotEmpty
            ? double.tryParse(_weightCtrl.text)
            : null,
        length: _lengthCtrl.text.isNotEmpty
            ? double.tryParse(_lengthCtrl.text)
            : null,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
        caughtAt: _caughtAt,
      );

      if (_isEditing) {
        await DatabaseService.instance
            .updateCatch(catchItem.copyWith(id: widget.existingCatch!.id));
      } else {
        await DatabaseService.instance.addCatch(catchItem);
      }
      WidgetService.updateWidget();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
      setState(() => _saving = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Add Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoFile = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy  h:mm a').format(_caughtAt);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Catch' : 'Add Catch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _photoFile != null
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    width: _photoFile != null ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: _photoFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_photoFile!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text('Tap to change',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Tap to add a photo',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location + Weather
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _fetchingLocation ? null : _getLocation,
                    icon: _fetchingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Icon(
                            _hasLocation
                                ? Icons.my_location
                                : Icons.location_disabled,
                            size: 18,
                          ),
                    label: Text(
                      _hasLocation
                          ? '${_latitude!.toStringAsFixed(3)}, ${_longitude!.toStringAsFixed(3)}'
                          : 'Get GPS location',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_hasWeather) ...[const SizedBox(width: 8),
                  Chip(
                    avatar: Icon(Icons.wb_sunny, size: 16),
                    label: Text(
                        '${_weatherTemp!.round()}°C $_weatherCondition'),
                  ),
                ],
                if (_fetchingWeather) ...[const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Angler
            TextFormField(
              controller: _anglerCtrl,
              decoration: const InputDecoration(
                labelText: 'Angler *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            // Species
            TextFormField(
              controller: _speciesCtrl,
              decoration: const InputDecoration(
                labelText: 'Species *',
                prefixIcon: Icon(Icons.emoji_nature),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),

            // Lure
            TextFormField(
              controller: _lureCtrl,
              decoration: const InputDecoration(
                labelText: 'Lure / Bait',
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 14),

            // Weight & Length
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lengthCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Length (cm)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date & Time
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateStr,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Catch'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
