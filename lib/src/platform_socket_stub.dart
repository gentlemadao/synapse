import 'platform_socket.dart';

PlatformSocket getPlatformSocketImpl() => throw UnsupportedError(
  'Cannot create PlatformSocket without platform implementations',
);
