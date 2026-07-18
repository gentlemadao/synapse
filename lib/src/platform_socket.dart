import 'platform_socket_stub.dart'
    if (dart.library.js_interop) 'platform_socket_web.dart'
    if (dart.library.io) 'platform_socket_io.dart';

abstract class PlatformSocket {
  Future<void> connect(
    String url, {
    required void Function(String) onMessage,
    required void Function() onDone,
    required void Function(dynamic) onError,
  });
  void send(String data);
  void close();
}

PlatformSocket getPlatformSocket() => getPlatformSocketImpl();
