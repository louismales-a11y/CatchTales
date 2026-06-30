import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/catch.dart';
import '../services/database_service.dart';
import '../services/help_text.dart';
import '../services/weather_service.dart';
import '../services/widget_service.dart';
import 'selfie_camera_screen.dart';

class AddCatchScreen extends StatefulWidget {
  final Catch? existingCatch;
  final String? initialAngler;
  final String? initialSpecies;

  const AddCatchScreen({super.key, this.existingCatch, this.initialAngler, this.initialSpecies});

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

  // Voice
  late stt.SpeechToText _speech;
  bool _voiceOn = false;
  String _voiceStatus = '';
  String _lastVoiceText = '';
  bool _saving = false;
  bool _fetchingLocation = false;
  bool _fetchingWeather = false;

  double? _latitude;
  double? _longitude;
  double? _weatherTemp;
  String? _weatherCondition;
  bool _useMetric = true;

  String get _weightUnit => _useMetric ? 'kg' : 'lb';
  String get _lengthUnit => _useMetric ? 'cm' : 'in';

  bool get _isEditing => widget.existingCatch != null;
  bool get _hasLocation => _latitude != null && _longitude != null;
  bool get _hasWeather => _weatherTemp != null;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
      _useMetric = c.weightUnit == 'kg' || c.lengthUnit == 'cm';
    } else {
      if (widget.initialAngler != null) _anglerCtrl.text = widget.initialAngler!;
      if (widget.initialSpecies != null) _speciesCtrl.text = widget.initialSpecies!;
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
    _speech.stop();
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
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  /// Open a selfie camera view (front camera) via the camera package.
  Future<void> _openSelfieCamera() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SelfieCameraScreen()),
    );
    if (path != null && mounted) {
      setState(() => _photoFile = File(path));
    }
  }

  Future<void> _pickFromTackleBox() async {
    final items = await DatabaseService.instance.getTackleItems();
    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your tackle box is empty')),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pick from Tackle Box'),
        children: items.map((item) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, item.name),
          child: Row(
            children: [
              item.photoPath != null && File(item.photoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(item.photoPath!),
                        width: 32, height: 32, fit: BoxFit.cover,
                        errorBuilder: (a,b,c) => const Icon(Icons.set_meal, size: 24),
                      ),
                    )
                  : const Icon(Icons.set_meal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 14)),
                    Text(item.type, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
    if (result != null && mounted) {
      _lureCtrl.text = result;
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
        weightUnit: _weightUnit,
        length: _lengthCtrl.text.isNotEmpty
            ? double.tryParse(_lengthCtrl.text)
            : null,
        lengthUnit: _lengthUnit,
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

  // ── Voice Commands ──────────────────────────────────────────────

  Future<void> _toggleVoice() async {
    if (_voiceOn) {
      _speech.stop();
      setState(() => _voiceOn = false);
    } else {
      _startVoice();
    }
  }

  Future<void> _startVoice() async {
    // Stop any existing session (e.g. from counter screen)
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 500));
    // Re-initialize to register our own onError/onStatus callbacks
    _speech = stt.SpeechToText();
    final available = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() => _voiceOn = false);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_voiceOn) _startVoice();
        });
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _voiceOn = false);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_voiceOn) _startVoice();
          });
        }
      },
    );
    if (!available) return;
    setState(() => _voiceOn = true);
    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final t = result.recognizedWords.toLowerCase().trim();
        if (t == _lastVoiceText) return;
        _lastVoiceText = t;
        _processVoice(t);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 60),
      ),
    );
  }

  void _processVoice(String text) {
    setState(() => _voiceStatus = '\"$text\"');

    // Take photo — open selfie camera (front-facing)
    if (text.contains('photo') || text.contains('camera') ||
        text.contains('snap') || text.contains('picture') ||
        text == 'shoot') {
      _openSelfieCamera();
      return;
    }

    // Weight: "weighs 5 lb" or "weight 2.5 kg"
    final weightMatch = RegExp(r'(weighs?|weight|mass)\s+([\d.]+)\s*(lb|lbs|kg|kilos|pounds)?').firstMatch(text);
    if (weightMatch != null) {
      final value = double.tryParse(weightMatch.group(2)!);
      final unit = weightMatch.group(3)?.toLowerCase() ?? '';
      if (value != null) {
        if (unit == 'kg' || unit == 'kilos') {
          _useMetric = true;
          _weightCtrl.text = value.toStringAsFixed(1);
        } else {
          _useMetric = false;
          _weightCtrl.text = value.toStringAsFixed(1);
        }
        setState(() {});
      }
      return;
    }

    // Length: "length 20 inches" or "measures 50 cm"
    final lengthMatch = RegExp(r'(length|measure|size|long)\s+([\d.]+)\s*(inch|in|inches|cm|centimeters|")?').firstMatch(text);
    if (lengthMatch != null) {
      final value = double.tryParse(lengthMatch.group(2)!);
      final unit = lengthMatch.group(3)?.toLowerCase() ?? '';
      if (value != null) {
        if (unit == 'cm' || unit == 'centimeters') {
          _useMetric = true;
        } else {
          _useMetric = false;
        }
        _lengthCtrl.text = value.toStringAsFixed(1);
        setState(() {});
      }
      return;
    }

    // Save / Done
    if (text.startsWith('save') || text.startsWith('done') ||
        text == 'finish' || text == 'submit') {
      _save();
      return;
    }

    setState(() => _voiceStatus = '❓ Unrecognized: \"$text\"');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy  h:mm a').format(_caughtAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catch' : 'Add Catch'),
        actions: [helpButton(context, 'add_catch')],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom + 80),
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

            // Lure (with tackle box picker)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lureCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lure / Bait',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 56,
                  child: Tooltip(
                    message: 'Pick from tackle box',
                    child: IconButton(
                      icon: const Icon(Icons.inventory_2, size: 20),
                      onPressed: _pickFromTackleBox,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Unit toggle
            Row(
              children: [
                const Text('Units:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Metric', style: TextStyle(fontSize: 12)),
                  selected: _useMetric,
                  onSelected: (_) => setState(() => _useMetric = true),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Imperial', style: TextStyle(fontSize: 12)),
                  selected: !_useMetric,
                  onSelected: (_) => setState(() => _useMetric = false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Weight & Length
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    decoration: InputDecoration(
                      labelText: 'Weight ($_weightUnit)',
                      prefixIcon: const Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lengthCtrl,
                    decoration: InputDecoration(
                      labelText: 'Length ($_lengthUnit)',
                      prefixIcon: const Icon(Icons.straighten),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _toggleVoice,
        backgroundColor: _voiceOn ? Colors.red : theme.colorScheme.primary,
        child: Icon(
          _voiceOn ? Icons.mic : Icons.mic_none,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: _voiceStatus.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _voiceStatus,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
