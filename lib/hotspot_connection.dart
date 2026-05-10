import 'dart:math';
import 'hotspot_connection_platform_interface.dart';
import 'models/peer.dart';
import 'models/room_event.dart';
import 'models/room_result.dart';

export 'models/peer.dart';
export 'models/room_event.dart';
export 'models/room_result.dart';

class HotspotConnection {
  String? _myPeerId;

  String get myPeerId {
    if (_myPeerId == null) {
      final random = Random();
      _myPeerId = 'peer_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}';
    }
    return _myPeerId!;
  }

  Future<String?> getPlatformVersion() {
    return HotspotConnectionPlatform.instance.getPlatformVersion();
  }

  Future<void> startBroadcasting(String username) {
    return HotspotConnectionPlatform.instance.startBroadcasting(username, myPeerId);
  }

  Future<void> startDiscovery() {
    return HotspotConnectionPlatform.instance.startDiscovery();
  }

  Future<void> stopDiscovery() {
    return HotspotConnectionPlatform.instance.stopDiscovery();
  }

  Future<RoomResult> createRoom(List<String> deviceIds) {
    return HotspotConnectionPlatform.instance.createRoom(deviceIds);
  }

  Future<void> sendMessage(String message) {
    return HotspotConnectionPlatform.instance.sendMessage(message);
  }

  Stream<Peer> get discoveryEvents {
    return HotspotConnectionPlatform.instance.discoveryEvents;
  }

  Stream<RoomEvent> get roomEvents {
    return HotspotConnectionPlatform.instance.roomEvents;
  }
}
