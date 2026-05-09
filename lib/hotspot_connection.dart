import 'hotspot_connection_platform_interface.dart';

class HotspotConnection {
  Future<String?> getPlatformVersion() {
    return HotspotConnectionPlatform.instance.getPlatformVersion();
  }

  Future<void> startBroadcasting(String username) {
    return HotspotConnectionPlatform.instance.startBroadcasting(username);
  }

  Future<void> startDiscovery() {
    return HotspotConnectionPlatform.instance.startDiscovery();
  }

  Future<void> stopDiscovery() {
    return HotspotConnectionPlatform.instance.stopDiscovery();
  }

  Future<void> createRoom(List<String> deviceIds) {
    return HotspotConnectionPlatform.instance.createRoom(deviceIds);
  }

  Future<void> sendMessage(String message) {
    return HotspotConnectionPlatform.instance.sendMessage(message);
  }

  Stream<String> get discoveryEvents {
    return HotspotConnectionPlatform.instance.discoveryEvents;
  }

  Stream<Map<String, dynamic>> get roomEvents {
    return HotspotConnectionPlatform.instance.roomEvents;
  }
}
