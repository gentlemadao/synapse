// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'platform_socket.dart';

class PlatformSocketImpl implements PlatformSocket {
  html.WebSocket? _socket;
  StreamSubscription? _onMessageSub;
  StreamSubscription? _onCloseSub;
  StreamSubscription? _onErrorSub;

  @override
  Future<void> connect(
    String url, {
    required void Function(String) onMessage,
    required void Function() onDone,
    required void Function(dynamic) onError,
  }) async {
    final completer = Completer<void>();
    final ws = html.WebSocket(url);
    _socket = ws;

    _onMessageSub = ws.onMessage.listen((html.MessageEvent event) {
      final data = event.data;
      if (data is String) {
        onMessage(data);
      }
    });

    _onCloseSub = ws.onClose.listen((_) {
      onDone();
    });

    _onErrorSub = ws.onError.listen((html.Event error) {
      onError(error);
    });

    ws.onOpen.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });

    // Handle initial connection failure if WebSocket closes before open
    ws.onClose.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('WebSocket connection closed before opening'),
        );
      }
    });

    await completer.future;
  }

  @override
  void send(String data) {
    _socket?.send(data);
  }

  @override
  void close() {
    _onMessageSub?.cancel();
    _onCloseSub?.cancel();
    _onErrorSub?.cancel();
    _socket?.close();
  }
}

PlatformSocket getPlatformSocketImpl() => PlatformSocketImpl();
