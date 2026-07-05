import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Simple selfie camera screen — uses front camera and auto-captures
/// after a short countdown so you can pose with your fish.
class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  int _countdown = 3;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (!mounted) return;
    // Find front camera, fall back to first available
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(front, ResolutionPreset.medium);
    _initializeFuture = _controller!.initialize();
    setState(() {});
    // Auto-start countdown after camera is ready
    _initializeFuture?.then((_) => _startCountdown());
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 1) {
        timer.cancel();
        _capture();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _capture() async {
    if (_capturing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating,
              content: Text('Camera error: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Selfie'),
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: Text('Camera not available', style: TextStyle(color: Colors.white)));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              CameraPreview(_controller!),
              // Countdown overlay
              if (!_capturing)
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_capturing)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Capturing...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
