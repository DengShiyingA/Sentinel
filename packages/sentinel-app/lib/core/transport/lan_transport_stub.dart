import 'transport.dart';
import '../../shared/models/approval_request.dart';

class LanTransport extends Transport {
  @override
  final ConnectionMode mode = ConnectionMode.lan;

  @override
  bool get isConnected => false;

  Future<void> connectTo(String host, int port) async {
    throw UnsupportedError('LAN transport is not supported on Web. Use Server mode.');
  }

  @override
  Future<void> connect() async => throw UnsupportedError('Use Server mode on Web');

  @override
  void disconnect() {}

  @override
  void sendDecision(String requestId, Decision decision) {}

  @override
  void sendUserMessage(String text) {}
}
