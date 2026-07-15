import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/app_constants.dart';

/// On-device face recognition service using MobileFaceNet TFLite.
///
/// Responsibilities:
/// - Load MobileFaceNet model at app startup
/// - Preprocess face images (crop, resize 112×112, normalize)
/// - Extract 192-dim embedding vectors
/// - Compare embeddings via Euclidean distance
/// - Cache stored embeddings locally for offline matching
class FaceRecognitionService {
  FaceRecognitionService._();

  static Interpreter? _interpreter;
  static const _storage = FlutterSecureStorage();
  static const _embeddingKey = 'face_embeddings_cache_v2';

  // ── Initialization ──────────────────────────────────────────

  /// Load the TFLite model. Call once at app startup.
  static Future<void> init() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        AppConstants.faceModelPath,
      );
    } catch (e) {
      throw Exception('Gagal memuat model face recognition: $e');
    }
  }

  /// Release resources.
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  static bool get isReady => _interpreter != null;

  // ── Embedding Extraction ────────────────────────────────────

  /// Extract a 192-dim embedding from an image file path.
  ///
  /// [imagePath] – Path to the captured image file on disk.
  /// [faceRect]  – Optional ML Kit bounding box to crop the face region.
  ///               If null, the entire image is used (assume already cropped).
  static Future<List<double>> extractEmbedding(
    String imagePath, {
    ui.Rect? faceRect,
  }) async {
    if (_interpreter == null) {
      throw Exception('Model belum dimuat. Panggil init() terlebih dahulu.');
    }

    final byteData = faceRect == null
        ? await _decodeAndResizeNative(imagePath)
        : await _decodeCropAndResizeNative(imagePath, faceRect);

    return _runInferenceFromByteData(byteData);
  }

  /// Extract embedding from an already-decoded [img.Image].
  /// Useful when the face is already cropped in memory.
  static Future<List<double>> extractEmbeddingFromImage(
    img.Image faceImage,
  ) async {
    if (_interpreter == null) {
      throw Exception('Model belum dimuat. Panggil init() terlebih dahulu.');
    }
    return _runInference(faceImage);
  }

  /// Core inference: resize → normalize → run model → L2 normalize output.
  static List<double> _runInference(img.Image faceImage) {
    // Resize to 112×112
    final resized = img.copyResize(
      faceImage,
      width: AppConstants.faceInputSize,
      height: AppConstants.faceInputSize,
      interpolation: img.Interpolation.linear,
    );

    // Build input tensor [1, 112, 112, 3] with pixel values in [-1, 1]
    final input = _imageToInputTensor(resized);

    // Allocate output tensor [1, 192]
    final output = List.filled(AppConstants.faceEmbeddingSize, 0.0)
        .reshape([1, AppConstants.faceEmbeddingSize]);

    _interpreter!.run(input, output);

    // L2-normalize the raw embedding
    return _l2Normalize(List<double>.from(output[0] as List));
  }

  /// Core inference from native RGBA bytes that are already 112x112.
  static List<double> _runInferenceFromByteData(ByteData byteData) {
    final input = _byteDataToInputTensor(byteData);

    final output = List.filled(AppConstants.faceEmbeddingSize, 0.0)
        .reshape([1, AppConstants.faceEmbeddingSize]);

    _interpreter!.run(input, output);

    return _l2Normalize(List<double>.from(output[0] as List));
  }

  // ── Face Matching ───────────────────────────────────────────

  /// Compare a new face embedding against a list of stored embeddings.
  ///
  /// Uses the best (smallest) Euclidean distance across all stored embeddings.
  static FaceMatchResult compareFaces(
    List<double> currentEmbedding,
    List<List<double>> storedEmbeddings,
  ) {
    if (!_isValidEmbedding(currentEmbedding) || storedEmbeddings.isEmpty) {
      return const FaceMatchResult(
        match: false,
        distance: double.infinity,
        confidence: 0.0,
        message: 'Data wajah tidak valid',
      );
    }

    final validStored = storedEmbeddings.where(_isValidEmbedding).toList();
    if (validStored.isEmpty) {
      return const FaceMatchResult(
        match: false,
        distance: double.infinity,
        confidence: 0.0,
        message: 'Data wajah tersimpan tidak valid',
      );
    }

    final distances = validStored
        .map((stored) => _euclideanDistance(currentEmbedding, stored))
        .toList()
      ..sort();
    final bestDistance = distances.first;
    final topCount = distances.length >= 2 ? 2 : 1;
    final topAverage =
        distances.take(topCount).reduce((a, b) => a + b) / topCount;

    final match = distances.length == 1
        ? bestDistance <= AppConstants.faceMatchThreshold
        : bestDistance <= AppConstants.faceMatchThreshold &&
            topAverage <= AppConstants.faceMatchThresholdRelaxed;
    final confidence =
        ((1.0 - (topAverage / (AppConstants.faceMatchThresholdRelaxed * 1.6))) *
                100)
            .clamp(0.0, 100.0);

    return FaceMatchResult(
      match: match,
      distance: topAverage,
      confidence: confidence,
      message: match ? 'Wajah terverifikasi' : 'Wajah tidak cocok',
    );
  }

  static bool areEmbeddingsConsistent(List<List<double>> embeddings) {
    final valid = embeddings.where(_isValidEmbedding).toList();
    if (valid.length < 2) return valid.length == embeddings.length;

    for (int i = 0; i < valid.length; i++) {
      for (int j = i + 1; j < valid.length; j++) {
        final distance = _euclideanDistance(valid[i], valid[j]);
        if (distance > AppConstants.faceRegistrationConsistencyThreshold) {
          return false;
        }
      }
    }
    return valid.length == embeddings.length;
  }

  // ── Embedding Cache (Offline Support) ────────────────────────

  /// Persist embeddings locally for offline face matching.
  static Future<void> cacheEmbeddings(List<List<double>> embeddings) async {
    await _storage.write(key: _embeddingKey, value: jsonEncode(embeddings));
  }

  /// Load cached embeddings. Returns null if nothing is cached.
  static Future<List<List<double>>?> getCachedEmbeddings() async {
    final raw = await _storage.read(key: _embeddingKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) =>
              List<double>.from((e as List).map((v) => (v as num).toDouble())))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Clear cached embeddings (e.g. on logout or re-registration).
  static Future<void> clearCache() async {
    await _storage.delete(key: _embeddingKey);
  }

  // ── Private Helpers ──────────────────────────────────────────

  static Future<ByteData> _decodeAndResizeNative(String imagePath) async {
    final fileBytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      fileBytes,
      targetWidth: AppConstants.faceInputSize,
      targetHeight: AppConstants.faceInputSize,
    );
    final frame = await codec.getNextFrame();
    final uiImage = frame.image;

    final byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    uiImage.dispose();

    if (byteData == null) {
      throw Exception('Gagal mendapatkan ByteData dari gambar.');
    }
    return byteData;
  }

  static Future<ByteData> _decodeCropAndResizeNative(
    String imagePath,
    ui.Rect faceRect,
  ) async {
    final fileBytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(fileBytes);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;

    final maxWidth = sourceImage.width.toDouble();
    final maxHeight = sourceImage.height.toDouble();
    final left = faceRect.left.clamp(0.0, maxWidth - 1);
    final top = faceRect.top.clamp(0.0, maxHeight - 1);
    final right = faceRect.right.clamp(left + 1, maxWidth);
    final bottom = faceRect.bottom.clamp(top + 1, maxHeight);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final destination = ui.Rect.fromLTWH(
      0,
      0,
      AppConstants.faceInputSize.toDouble(),
      AppConstants.faceInputSize.toDouble(),
    );
    canvas.drawImageRect(
      sourceImage,
      ui.Rect.fromLTRB(left, top, right, bottom),
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(
      AppConstants.faceInputSize,
      AppConstants.faceInputSize,
    );
    picture.dispose();
    sourceImage.dispose();

    final byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    resizedImage.dispose();

    if (byteData == null) {
      throw Exception('Gagal mendapatkan ByteData dari gambar.');
    }
    return byteData;
  }

  /// Build a [1, 112, 112, 3] input tensor from native RGBA bytes.
  /// Pixel values are normalized from [0, 255] to [-1, 1].
  static List<List<List<List<double>>>> _byteDataToInputTensor(
    ByteData byteData,
  ) {
    return List.generate(1, (_) {
      return List.generate(AppConstants.faceInputSize, (y) {
        return List.generate(AppConstants.faceInputSize, (x) {
          final offset = (y * AppConstants.faceInputSize + x) * 4;
          final r = byteData.getUint8(offset).toDouble();
          final g = byteData.getUint8(offset + 1).toDouble();
          final b = byteData.getUint8(offset + 2).toDouble();
          return [
            (r - 127.5) / 127.5,
            (g - 127.5) / 127.5,
            (b - 127.5) / 127.5,
          ];
        });
      });
    });
  }
  /// Build a [1, 112, 112, 3] input tensor from an [img.Image].
  /// Pixel values are normalized from [0, 255] to [-1, 1].
  static List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    return List.generate(1, (_) {
      return List.generate(AppConstants.faceInputSize, (y) {
        return List.generate(AppConstants.faceInputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r.toDouble() - 127.5) / 127.5,
            (pixel.g.toDouble() - 127.5) / 127.5,
            (pixel.b.toDouble() - 127.5) / 127.5,
          ];
        });
      });
    });
  }

  static bool _isValidEmbedding(List<double> embedding) {
    return embedding.length == AppConstants.faceEmbeddingSize &&
        embedding.every((value) => value.isFinite);
  }

  /// L2-normalize a vector so its magnitude is 1.
  static List<double> _l2Normalize(List<double> vector) {
    double sumSquare = 0;
    for (final v in vector) {
      sumSquare += v * v;
    }
    final norm = sqrt(sumSquare);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Euclidean distance between two vectors.
  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}

/// Result from a face matching operation.
class FaceMatchResult {
  final bool match;
  final double distance;
  final double confidence;
  final String message;

  const FaceMatchResult({
    required this.match,
    required this.distance,
    required this.confidence,
    required this.message,
  });
}
