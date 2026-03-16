import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// Plays raw PCM-16 audio chunks pushed from the AI WebSocket stream.
///
/// Sample rate must match the server-side TTS output (currently 24 000 Hz).
class AudioPlaybackService {
  bool _initialized = false;
  bool _stopping = false;

  // Must match the sample rate of the TTS engine on the backend.
  static const int _sampleRate = 24000;

  // Low-water threshold in PCM samples. When the driver's internal buffer
  // falls below this value it fires the optional feed callback.
  // 8000 samples @ 24 kHz ≈ 333 ms of look-ahead — keeps playback gapless.
  static const int _feedThreshold = 6000;

  Future<void> initialize() async {
    if (_initialized || _stopping) return;
    await FlutterPcmSound.setLogLevel(LogLevel.none);
    await FlutterPcmSound.setup(sampleRate: _sampleRate, channelCount: 1);
    await FlutterPcmSound.setFeedThreshold(_feedThreshold);
    _initialized = true;
  }

  /// Re-initialise after a stop/release cycle (e.g. on conversation resume).
  Future<void> start() async {
    if (!_initialized) await initialize();
  }

  /// Push one chunk of raw PCM-16 bytes received from the WebSocket.
  ///
  /// The bytes are reinterpreted as signed 16-bit samples in-place
  /// (zero-copy) before being handed to the native audio driver.
  void add(Uint8List pcmBytes) {
    if (!_initialized || _stopping || pcmBytes.isEmpty) return;

    final evenLength = pcmBytes.lengthInBytes & ~1;
    if (evenLength <= 0) return;

    final samples = pcmBytes.buffer.asInt16List(
      pcmBytes.offsetInBytes,
      evenLength ~/ 2,
    );
    unawaited(_safeFeed(samples));
  }

  Future<void> _safeFeed(Int16List samples) async {
    if (!_initialized || _stopping || samples.isEmpty) return;
    try {
      await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
    } catch (_) {
      // Ignore transient feed errors while engine is being restarted/stopped.
    }
  }

  // Clears queued AI output chunks and restarts playback engine quickly.
  Future<void> clearGeneratedAudio() async {
    if (!_initialized || _stopping) return;

    _stopping = true;
    try {
      await FlutterPcmSound.release();
      await FlutterPcmSound.setup(sampleRate: _sampleRate, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(_feedThreshold);
      _initialized = true;
    } finally {
      _stopping = false;
    }
  }

  /// Releases the native audio engine. Call [start] to resume afterwards.
  Future<void> stop() async {
    if (!_initialized) return;

    _stopping = true;
    try {
      await FlutterPcmSound.release();
      _initialized = false;
    } finally {
      _stopping = false;
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}
