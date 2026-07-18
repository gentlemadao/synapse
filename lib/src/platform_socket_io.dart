import 'dart:io';
import 'platform_socket.dart';

class PlatformSocketImpl implements PlatformSocket {
  WebSocket? _socket;

  @override
  Future<void> connect(
    String url, {
    required void Function(String) onMessage,
    required void Function() onDone,
    required void Function(dynamic) onError,
  }) async {
    _socket = await WebSocket.connect(url);
    _socket!.listen(
      (data) {
        if (data is String) {
          onMessage(data);
        }
      },
      onDone: onDone,
      onError: onError,
    );
  }

  @override
  void send(String data) {
    _socket?.add(data);
  }

  @override
  void close() {
    _socket?.close();
  }
}

PlatformSocket getPlatformSocketImpl() => PlatformSocketImpl();
