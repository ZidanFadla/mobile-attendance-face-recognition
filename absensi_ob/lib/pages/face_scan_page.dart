import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class FaceScanPage extends StatefulWidget {
  final String? instruction; // instruksi foto (untuk registrasi multi foto)
  const FaceScanPage({super.key, this.instruction});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  String? _brightnessWarning;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  // Cek kecerahan gambar
  Future<double> _checkBrightness(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return 0;

    double total = 0;
    int count = 0;
    for (int y = 0; y < decoded.height; y += 10) {
      for (int x = 0; x < decoded.width; x += 10) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        total += (0.299 * r + 0.587 * g + 0.114 * b);
        count++;
      }
    }
    return total / count; // 0-255
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _brightnessWarning = null;
    });

    try {
      final photo = await _cameraController!.takePicture();

      // Cek kecerahan
      final brightness = await _checkBrightness(photo.path);

      if (brightness < 50) {
        // Terlalu gelap
        setState(() {
          _brightnessWarning =
              '⚠️ Cahaya terlalu gelap! Pindah ke tempat yang lebih terang.';
          _isProcessing = false;
        });
        return;
      }

      if (brightness > 230) {
        // Terlalu terang/silau
        setState(() {
          _brightnessWarning =
              '⚠️ Cahaya terlalu terang/silau! Hindari cahaya langsung.';
          _isProcessing = false;
        });
        return;
      }

      // Cahaya OK, lanjut
      if (mounted) Navigator.pop(context, photo.path);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Scan Wajah", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Instruksi foto
          if (widget.instruction != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.indigo,
              child: Text(
                widget.instruction!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Kamera
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_cameraController!),

                // Overlay oval wajah
                CustomPaint(
                  painter: _FaceOvalPainter(),
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),

          // Warning cahaya
          if (_brightnessWarning != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade800,
              child: Text(
                _brightnessWarning!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),

          // Tips cahaya
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black,
            child: const Text(
              '💡 Pastikan wajah terlihat jelas dan cahaya cukup',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

          // Tombol ambil foto
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isProcessing ? null : _takePicture,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Ambil Foto",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Overlay oval untuk panduan posisi wajah
class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(ovalRect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
