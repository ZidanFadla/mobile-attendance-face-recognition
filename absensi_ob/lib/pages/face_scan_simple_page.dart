import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../core/app_theme.dart';

/// Face scan page with camera + capture.
/// Server handles all validation — this is just a capture UI.
class FaceScanSimplePage extends StatefulWidget {
  final String? instruction;
  final bool isVideo;

  const FaceScanSimplePage({super.key, this.instruction, this.isVideo = false});

  @override
  State<FaceScanSimplePage> createState() => _FaceScanSimplePageState();
}

class _FaceScanSimplePageState extends State<FaceScanSimplePage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isRecording = false;

  late AnimationController _scanlineController;
  late Animation<double> _scanlineAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scanlineAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanlineController, curve: Curves.easeInOut),
    );
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
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
        await Future.delayed(const Duration(seconds: 3));
        final video = await _controller!.stopVideoRecording();
        if (mounted) Navigator.pop(context, video.path);
      } else {
        final photo = await _controller!.takePicture();
        if (mounted) Navigator.pop(context, photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isProcessing = false;
          _isRecording = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.armyGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (widget.instruction != null) _buildInstruction(),
            Expanded(child: _buildCameraPreview()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.isVideo ? 'Rekam Wajah' : 'Scan Wajah',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.armyGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        widget.instruction!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(_controller!),
        // Face guide oval with animated scanline
        CustomPaint(
          painter: _FaceGuidePainter(),
          child: const SizedBox.expand(),
        ),
        // Animated scanning line
        AnimatedBuilder(
          animation: _scanlineAnimation,
          builder: (context, _) {
            return Positioned(
              top: MediaQuery.of(context).size.height *
                  0.1 *
                  _scanlineAnimation.value +
                  MediaQuery.of(context).size.height * 0.08,
              left: MediaQuery.of(context).size.width * 0.2,
              right: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.btnGreen.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Text(
            widget.isVideo
                ? 'Hadapkan wajah ke kamera selama 3 detik'
                : 'Posisikan wajah di dalam oval',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Circular shutter button
          GestureDetector(
            onTap: _isProcessing ? null : _capture,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.armyGreen.withValues(alpha: 0.5),
                  width: 4,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessing ? AppTheme.textMuted : AppTheme.armyGreen,
                ),
                child: _isProcessing
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Icon(
                        widget.isVideo
                            ? Icons.videocam_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for face guide oval
class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer subtle glow
    final glowPaint = Paint()
      ..color = AppTheme.btnGreen.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(rect, glowPaint);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
