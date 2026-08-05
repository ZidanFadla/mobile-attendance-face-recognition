import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../core/app_theme.dart';
import '../services/face_recognition_service.dart';

/// Face scan page with camera + on-device face recognition.
/// Extracts MobileFaceNet embedding locally after capture.
class FaceScanSimplePage extends StatefulWidget {
  final String? instruction;
  final bool isVideo;
  final bool requireLiveness;

  const FaceScanSimplePage({
    super.key,
    this.instruction,
    this.isVideo = false,
    this.requireLiveness = false,
  });

  @override
  State<FaceScanSimplePage> createState() => _FaceScanSimplePageState();
}

class _FaceScanSimplePageState extends State<FaceScanSimplePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  FaceDetector? _faceDetector;
  Timer? _idleTimer;
  bool _isCameraInitializing = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isDetecting = false;
  bool _livenessPassed = false;
  bool _blinkPassed = false;
  bool _eyesWereOpen = false;
  bool _eyesWereClosed = false;
  late final List<bool> _turnChallenges;
  int _turnStep = 0;
  double? _neutralYaw;
  DateTime? _turnPromptedAt;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _livenessStatus = 'Posisikan satu wajah di dalam oval';

  late AnimationController _scanlineController;
  late Animation<double> _scanlineAnimation;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final firstTurnLeft = Random().nextBool();
    _turnChallenges = [firstTurnLeft, !firstTurnLeft];
    if (widget.requireLiveness) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          minFaceSize: 0.2,
        ),
      );
    }
    _startIdleTimer();
    _initCamera();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scanlineAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanlineController, curve: Curves.easeInOut),
    );
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 90), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu scan habis karena tidak ada aktivitas.'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _idleTimer?.cancel();
      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (_) {}
      }
      try {
        await controller.dispose();
      } catch (_) {}
      _controller = null;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _startIdleTimer();
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camera = frontCamera;

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _controller = controller;

      await controller.initialize();
      if (widget.requireLiveness) {
        await controller.startImageStream(_processCameraImage);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inisialisasi kamera: $e')),
        );
      }
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}

    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _disposeCameraAndDetector() async {
    await _disposeCamera();
    final detector = _faceDetector;
    _faceDetector = null;
    await detector?.close();
  }

  Future<void> _capture() async {
    if (_isProcessing ||
        _controller == null ||
        (widget.requireLiveness && !_livenessPassed)) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      if (widget.isVideo) {
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
        await Future.delayed(const Duration(seconds: 3));
        final video = await _controller!.stopVideoRecording();
        if (mounted) Navigator.pop(context, video.path);
      } else {
        final photo = await _controller!.takePicture();
        final face = await _detectSingleFaceFromFile(photo.path);

        // Extract embedding from the detected face crop, not the full frame.
        List<double>? embedding;
        if (FaceRecognitionService.isReady) {
          try {
            embedding = await FaceRecognitionService.extractEmbedding(
              photo.path,
              faceRect: face.boundingBox,
            );
          } catch (e) {
            debugPrint('Embedding extraction failed: $e');
          }
        }

        if (mounted) {
          Navigator.pop(context, {'path': photo.path, 'embedding': embedding});
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

  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now();
    if (_isDetecting ||
        _livenessPassed ||
        now.difference(_lastProcessedAt) < const Duration(milliseconds: 250)) {
      return;
    }

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null || _faceDetector == null) return;

    _isDetecting = true;
    _lastProcessedAt = now;
    try {
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isNotEmpty) {
        _startIdleTimer();
      }
      if (!mounted || _livenessPassed) return;

      if (faces.length != 1) {
        setState(() {
          _livenessStatus = faces.isEmpty
              ? 'Wajah belum terdeteksi'
              : 'Pastikan hanya satu wajah terlihat';
        });
        return;
      }

      final face = faces.first;
      if (!_isFaceBoxValid(
        face.boundingBox,
        Size(image.width.toDouble(), image.height.toDouble()),
      )) {
        setState(() {
          _livenessStatus = 'Posisikan wajah jelas di dalam oval';
        });
        return;
      }

      if (!_blinkPassed) {
        if (_checkBlink(face)) {
          setState(() {
            _blinkPassed = true;
            _livenessStatus = 'Kedipan terdeteksi. Hadapkan wajah lurus.';
          });
        } else if (mounted) {
          setState(() => _livenessStatus = _challengeInstruction);
        }
        return;
      }

      final turnResult = _checkTurnChallenge(face, now);
      if (turnResult == _TurnChallengeResult.completed) {
        await _completeLiveness();
      } else if (turnResult == _TurnChallengeResult.stepCompleted) {
        setState(() {
          _turnStep++;
          _neutralYaw = null;
          _turnPromptedAt = null;
          _livenessStatus = 'Bagus. Hadapkan wajah lurus lagi.';
        });
      } else if (mounted) {
        setState(() => _livenessStatus = _challengeInstruction);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _livenessStatus = 'Deteksi belum stabil, tahan wajah sebentar';
        });
      }
    } finally {
      _isDetecting = false;
    }
  }

  bool _checkBlink(Face face) {
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if (leftEye == null || rightEye == null) return false;

    if (leftEye > 0.75 && rightEye > 0.75) {
      if (_eyesWereClosed) return true;
      _eyesWereOpen = true;
    } else if (_eyesWereOpen && leftEye < 0.30 && rightEye < 0.30) {
      _eyesWereClosed = true;
    }
    return false;
  }

  _TurnChallengeResult _checkTurnChallenge(Face face, DateTime now) {
    final yaw = face.headEulerAngleY;
    if (yaw == null) return _TurnChallengeResult.waiting;

    const neutralLimit = 7.0;
    const turnThreshold = 16.0;
    const minimumReactionDelay = Duration(milliseconds: 600);

    if (_neutralYaw == null) {
      if (yaw.abs() > neutralLimit) {
        return _TurnChallengeResult.waiting;
      }
      _neutralYaw = yaw;
      _turnPromptedAt = now;
      return _TurnChallengeResult.waiting;
    }

    final promptedAt = _turnPromptedAt;
    if (promptedAt == null ||
        now.difference(promptedAt) < minimumReactionDelay) {
      return _TurnChallengeResult.waiting;
    }

    final delta = yaw - _neutralYaw!;
    final shouldTurnLeft = _turnChallenges[_turnStep];
    final passed = shouldTurnLeft
        ? delta <= -turnThreshold
        : delta >= turnThreshold;

    if (!passed) return _TurnChallengeResult.waiting;
    return _turnStep >= _turnChallenges.length - 1
        ? _TurnChallengeResult.completed
        : _TurnChallengeResult.stepCompleted;
  }

  bool _isFaceBoxValid(Rect box, Size imageSize) {
    if (box.width < 80 || box.height < 80) return false;

    final imageArea = imageSize.width * imageSize.height;
    if (imageArea <= 0) return false;

    final areaRatio = (box.width * box.height) / imageArea;
    return areaRatio >= 0.04 && areaRatio <= 0.75;
  }

  Future<Face> _detectSingleFaceFromFile(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        minFaceSize: 0.2,
      ),
    );

    try {
      final faces = await detector.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (faces.length != 1) {
        throw Exception(
          faces.isEmpty
              ? 'Wajah tidak terdeteksi. Pastikan wajah asli terlihat jelas.'
              : 'Terdeteksi lebih dari satu wajah. Pastikan hanya satu wajah di kamera.',
        );
      }

      final face = faces.first;
      if (face.boundingBox.width < 80 || face.boundingBox.height < 80) {
        throw Exception(
          'Wajah terlalu kecil atau tidak jelas. Dekatkan wajah ke kamera.',
        );
      }
      return face;
    } finally {
      await detector.close();
    }
  }

  Future<void> _completeLiveness() async {
    if (_livenessPassed || !mounted) return;
    setState(() {
      _livenessPassed = true;
      _livenessStatus = 'Liveness berhasil. Mengambil foto...';
    });

    if (_controller?.value.isStreamingImages == true) {
      await _controller!.stopImageStream();
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) await _capture();
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      compensation = camera.lensDirection == CameraLensDirection.front
          ? (sensorOrientation + compensation) % 360
          : (sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888) ||
        image.planes.length != 1) {
      return null;
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  String get _challengeInstruction {
    if (!_blinkPassed) return 'Kedipkan kedua mata satu kali';
    if (_neutralYaw == null) return 'Hadapkan wajah lurus ke kamera';
    return _turnChallenges[_turnStep]
        ? 'Tengok sedikit ke kiri'
        : 'Tengok sedikit ke kanan';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _scanlineController.dispose();
    unawaited(_disposeCameraAndDetector());
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
            if (widget.requireLiveness) _buildLivenessInstruction(),
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

  Widget _buildLivenessInstruction() {
    final passed = _livenessPassed;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: passed ? AppTheme.success : AppTheme.armyGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            passed ? 'Verifikasi gerakan berhasil' : _challengeInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _livenessStatus,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
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
              top:
                  MediaQuery.of(context).size.height *
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
            widget.requireLiveness
                ? (_livenessPassed
                      ? 'Tahan posisi, foto sedang diambil'
                      : 'Ikuti instruksi gerakan di atas')
                : widget.isVideo
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
            onTap: _isProcessing || (widget.requireLiveness && !_livenessPassed)
                ? null
                : _capture,
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
                  color:
                      _isProcessing ||
                          (widget.requireLiveness && !_livenessPassed)
                      ? AppTheme.textMuted
                      : AppTheme.armyGreen,
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

enum _TurnChallengeResult { waiting, stepCompleted, completed }
