import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as dev;

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  int _outgoingSequence = 0;
  int? _lastIncomingSequence;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'WEBSOCKET SERVICE',
      error: error,
      stackTrace: stackTrace,
    );
  }

  bool get isConnected => _channel != null;

  void connect(String wsUrl) {
    _trace('connect: wsUrl=$wsUrl');
    disconnect();
    _outgoingSequence = 0;
    _lastIncomingSequence = null;

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _socketSubscription = _channel!.stream.listen(
      (data) {
        final parsed = _parseIncomingMessage(data);
        final type = parsed['type']?.toString() ?? 'unknown';
        if (type != 'audio_chunk' && type != 'pong') {
          _trace('connect: incoming type=$type');
        }
        _messageController.add(parsed);
      },
      onDone: () {
        _trace('connect: socket done');
        _messageController.add({'type': 'disconnected', 'source': 'socket'});
      },
      onError: (e, stack) {
        _trace('connect: socket error', error: e, stackTrace: stack);
        _messageController.add({
          'type': 'error',
          'source': 'socket',
          'error': e.toString(),
        });
      },
    );
  }

  Map<String, dynamic> _parseIncomingMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return _normalizeParsedPayload(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return _normalizeParsedPayload(decoded);
        }
      } catch (_) {
        return {
          'type': 'error',
          'source': 'parser',
          'error': 'Invalid JSON payload',
        };
      }
    }

    if (data is List<int>) {
      try {
        final decoded = utf8.decode(data);
        final jsonDecoded = jsonDecode(decoded);
        if (jsonDecoded is Map<String, dynamic>) {
          return _normalizeParsedPayload(jsonDecoded);
        }
      } catch (_) {
        return {
          'type': 'error',
          'source': 'parser',
          'error': 'Invalid binary JSON payload',
        };
      }
    }

    return {'type': 'unknown', 'raw': data.toString()};
  }

  Map<String, dynamic> _normalizeParsedPayload(Map<String, dynamic> payload) {
    final seqValue = payload['seq'];
    if (seqValue is int) {
      if (_lastIncomingSequence != null && seqValue <= _lastIncomingSequence!) {
        _trace(
          '_normalizeParsedPayload: non-increasing incoming seq=$seqValue last=$_lastIncomingSequence type=${payload['type']}',
        );
      }
      _lastIncomingSequence = seqValue;
    }
    return payload;
  }

  void sendJson(Map<String, dynamic> payload) {
    if (_channel == null) {
      _trace('sendJson: skipped disconnected payloadType=${payload['type']}');
      return;
    }
    final type = payload['type']?.toString() ?? 'unknown';
    if (type != 'audio_chunk' && type != 'ping') {
      _trace('sendJson: type=$type');
    }
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e, stack) {
      _trace('sendJson: failed type=$type', error: e, stackTrace: stack);
    }
  }

  void sendAudio(Uint8List pcmChunk) {
    if (_channel == null) return;
    sendJson({
      'type': 'audio_chunk',
      'data': base64Encode(pcmChunk),
      'seq': ++_outgoingSequence,
    });
  }

  void sendVideoFrame({
    required Uint8List jpegBytes,
    required int width,
    required int height,
  }) {
    if (_channel == null) return;

    _trace(
      'sendVideoFrame: bytes=${jpegBytes.length} width=$width height=$height',
    );

    sendJson({
      'type': 'video_frame',
      'data': base64Encode(jpegBytes),
      'width': width,
      'height': height,
      'seq': ++_outgoingSequence,
    });
  }

  void sendText(String text) {
    if (text.trim().isEmpty || _channel == null) return;
    sendJson({'type': 'text_input', 'data': text, 'seq': ++_outgoingSequence});
  }

  void sendPing() {
    if (_channel == null) return;
    sendJson({'type': 'ping', 'seq': ++_outgoingSequence});
  }

  void sendInterrupt() {
    if (_channel == null) return;
    sendJson({'type': 'interrupt', 'seq': ++_outgoingSequence});
  }

  void sendControl({required String action, required String value}) {
    if (_channel == null || action.trim().isEmpty || value.trim().isEmpty) {
      return;
    }
    sendJson({
      'type': 'control',
      'action': action.trim(),
      'value': value.trim(),
      'seq': ++_outgoingSequence,
    });
  }

  void sendSessionInit(String sessionId) {
    if (_channel == null || sessionId.trim().isEmpty) return;
    sendJson({
      'type': 'session_init',
      'session_id': sessionId.trim(),
      'seq': ++_outgoingSequence,
    });
  }

  void disconnect() {
    _trace('disconnect: closing websocket');
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _lastIncomingSequence = null;
  }

  void dispose() {
    _trace('dispose: message controller closing');
    disconnect();
    _messageController.close();
  }
}
