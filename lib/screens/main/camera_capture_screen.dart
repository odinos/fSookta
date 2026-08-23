import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sookta_theme.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? controller;
  Object? error;
  var loading = true;
  var takingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final nextController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await nextController.initialize();
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      setState(() {
        controller = nextController;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _preview(camera)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: FilledButton(
                  onPressed: camera == null || takingPhoto ? null : _takePhoto,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SooktaColors.darkGreen,
                    shape: const CircleBorder(),
                    fixedSize: const Size(76, 76),
                  ),
                  child: takingPhoto
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, size: 34),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(CameraController? camera) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (camera == null || !camera.value.isInitialized) {
      return const Center(
        child:
            Text('Camera is not ready.', style: TextStyle(color: Colors.white)),
      );
    }

    return Center(
      child: CameraPreview(camera),
    );
  }

  Future<void> _takePhoto() async {
    final camera = controller;
    if (camera == null || !camera.value.isInitialized) return;

    setState(() => takingPhoto = true);
    try {
      final image = await camera.takePicture();
      if (mounted) Navigator.of(context).pop(image.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => takingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture photo: $e')),
      );
    }
  }
}
