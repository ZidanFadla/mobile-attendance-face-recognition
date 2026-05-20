import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../core/app_theme.dart';

/// Ultra Simple Face Scan Page
/// Hanya camera + capture, no validation logic
/// Server yang handle semua validasi
class FaceScanSimplePage extends StatefulWidget {
  final String? instruction;
  final bool isVideo;

  const FaceScanSimplePage({super.key, this.instruction, this.isVideo = false});

  @override
  State<FaceScanSimplePage> createState() => _FaceScanSimplePageState();
}

class _FaceScanSimplePageState extends State<FaceScanSimplePage> {
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inisialisasi kamera: $e')),
        );
      }
    }
  }

  Future<void> _capture() async {
    if (_isProcessing || _controller == null) return;

    setState(() => _isProcessing = true);

    try {
      if (widget.isVideo) {
        // Record video pendek (3 detik untuk liveness)
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);

        // Record selama 3 detik
        await Future.delayed(const Duration(seconds: 3));

        final video = await _controller!.stopVideoRecording();
        if (mounted) {
          Navigator.pop(context, video.path);
        }
      } else {
        // Ambil foto
        final photo = await _controller!.takePicture();
        if (mounted) {
          Navigator.pop(context, photo.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isProcessing = false;
          _isRecording = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.isVideo ? "Rekam Wajah" : "Scan Wajah",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Instruksi
          if (widget.instruction != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.armyGreen,
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

          // Camera Preview
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller!),

                // Guide oval
                CustomPaint(
                  painter: _FaceGuidePainter(),
                  child: const SizedBox.expand(),
                ),

                // Recording indicator
                if (_isRecording)
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'Recording...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tips
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            child: Text(
              widget.isVideo
                  ? 'Hadapkan wajah ke kamera selama 3 detik'
                  : 'Posisikan wajah di dalam oval',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

          // Tombol
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.armyGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isProcessing ? null : _capture,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.isVideo ? "Mulai Rekam" : "Ambil Foto",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter untuk guide oval
class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
