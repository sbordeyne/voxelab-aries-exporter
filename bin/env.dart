import 'dart:io' show Platform;

class Env {
  final String ariesIp = Platform.environment['ARIES_IP'] ?? '';
  final int ariesPort = int.parse(Platform.environment['ARIES_PORT'] ?? '8899');
  final int socketPollingInterval = int.parse(Platform.environment['SOCKET_POLLING_INTERVAL'] ?? '1000');
  final String hostName = Platform.environment['HOSTNAME'] ?? '0.0.0.0';
  final int port = int.parse(Platform.environment['PORT'] ?? '9000');
  Env();
}
