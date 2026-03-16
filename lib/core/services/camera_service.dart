import 'dart:typed_data';
import 'dart:developer' as dev;

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class VisionFrame {
  final Uint8List jpegBytes;
  final int width;
  final int height;

  const VisionFrame({
    required this.jpegBytes,
    required this.width,
    required this.height,
  });
}

class CameraService {
  CameraController? _controller;
  bool _isInitializing = false;
  bool _isCapturing = false;

  bool get isCapturing => _isCapturing;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'CAMERA SERVICE',
      error: error,
      stackTrace: stackTrace,
    );
  }

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized == true;

  Future<void> initialize() async {
    if (_isInitializing || isInitialized) {
      _trace(
        'initialize: skipped initializing=$_isInitializing ready=$isInitialized',
      );
      return;
    }

    _isInitializing = true;
    try {
      final cameras = await availableCameras();
      _trace('initialize: available cameras=${cameras.length}');
      if (cameras.isEmpty) {
        throw Exception('No camera available on this device');
      }

      final preferred = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final selected = preferred.isNotEmpty ? preferred.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _controller = controller;
      _trace(
        'initialize: ready lens=${selected.lensDirection.name} preview=${controller.value.previewSize}',
      );
    } catch (e, stack) {
      _trace('initialize: failed', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<VisionFrame?> captureOptimizedFrame({
    int maxWidth = 640,
    int maxHeight = 480,
    int jpegQuality = 60,
  }) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      _trace(
        'captureOptimizedFrame: skipped controller=${controller != null} initialized=${controller?.value.isInitialized == true} capturing=$_isCapturing',
      );
      return null;
    }

    _isCapturing = true;
    try {
      final file = await controller.takePicture();
      final sourceBytes = await file.readAsBytes();
      final decoded = img.decodeImage(sourceBytes);

      if (decoded == null) {
        return null;
      }

      final resized = _resizeKeepingAspect(
        decoded,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      final encoded = img.encodeJpg(resized, quality: jpegQuality);

      _trace(
        'captureOptimizedFrame: source=${decoded.width}x${decoded.height} optimized=${resized.width}x${resized.height} bytes=${encoded.length}',
      );

      return VisionFrame(
        jpegBytes: Uint8List.fromList(encoded),
        width: resized.width,
        height: resized.height,
      );
    } catch (e, stack) {
      _trace('captureOptimizedFrame: failed', error: e, stackTrace: stack);
      return null;
    } finally {
      _isCapturing = false;
    }
  }

  img.Image _resizeKeepingAspect(
    img.Image source, {
    required int maxWidth,
    required int maxHeight,
  }) {
    if (source.width <= maxWidth && source.height <= maxHeight) {
      return source;
    }

    final widthScale = maxWidth / source.width;
    final heightScale = maxHeight / source.height;
    final scale = widthScale < heightScale ? widthScale : heightScale;

    final targetWidth = (source.width * scale).round().clamp(1, maxWidth);
    final targetHeight = (source.height * scale).round().clamp(1, maxHeight);

    return img.copyResize(
      source,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );
  }

  Future<void> dispose() async {
    _trace('dispose: camera controller dispose requested');
    final startedAt = DateTime.now();
    while (_isCapturing) {
      if (DateTime.now().difference(startedAt) > const Duration(seconds: 2)) {
        _trace('dispose: timed out waiting for active capture to finish');
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    await _controller?.dispose();
    _controller = null;
  }
}
