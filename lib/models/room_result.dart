import 'peer.dart';

class RoomResult {
  final List<Peer> connectedPeers;
  final List<String> failedPeerIds;

  RoomResult({
    required this.connectedPeers,
    required this.failedPeerIds,
  });

  bool get isSuccess => connectedPeers.isNotEmpty;
}
