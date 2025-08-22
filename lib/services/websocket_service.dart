import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  bool _isConnected = false;

  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _channel.sink.close();
    _isConnected = false;
  }

  void sendLocation(double lat, double lng, double speed, double heading) {
    if (_isConnected) {
      final message = {
        'type': 'location_update',
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _channel.sink.add(jsonEncode(message));
    }
  }

  Stream<dynamic> get stream => _channel.stream;

  bool get isConnected => _isConnected;
}