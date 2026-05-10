import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'hotspot_connection_method_channel.dart';
import 'models/peer.dart';
import 'models/room_event.dart';
import 'models/room_result.dart';

abstract class HotspotConnectionPlatform extends PlatformInterface {
  HotspotConnectionPlatform() : super(token: _token);
  static final Object _token = Object();
  static HotspotConnectionPlatform _instance = MethodChannelHotspotConnection();
  static HotspotConnectionPlatform get instance => _instance;
  static set instance(HotspotConnectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> startBroadcasting(String username, String peerId) {
    throw UnimplementedError('startBroadcasting() has not been implemented.');
  }

  Future<void> startDiscovery() {
    throw UnimplementedError('startDiscovery() has not been implemented.');
  }

  Future<void> stopDiscovery() {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  Future<RoomResult> createRoom(List<String> deviceIds) {
    throw UnimplementedError('createRoom() has not been implemented.');
  }

  Future<void> sendMessage(String message) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  Stream<Peer> get discoveryEvents {
    throw UnimplementedError('discoveryEvents has not been implemented.');
  }

  Stream<RoomEvent> get roomEvents {
    throw UnimplementedError('roomEvents has not been implemented.');
  }
}
