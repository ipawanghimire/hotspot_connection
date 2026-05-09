import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hotspot_connection_method_channel.dart';

abstract class HotspotConnectionPlatform extends PlatformInterface {
  /// Constructs a HotspotConnectionPlatform.
  HotspotConnectionPlatform() : super(token: _token);

  static final Object _token = Object();

  static HotspotConnectionPlatform _instance = MethodChannelHotspotConnection();

  /// The default instance of [HotspotConnectionPlatform] to use.
  ///
  /// Defaults to [MethodChannelHotspotConnection].
  static HotspotConnectionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HotspotConnectionPlatform] when
  /// they register themselves.
  static set instance(HotspotConnectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Starts broadcasting the user's presence on the network.
  Future<void> startBroadcasting(String username) {
    throw UnimplementedError('startBroadcasting() has not been implemented.');
  }

  /// Starts discovering other broadcasting devices.
  Future<void> startDiscovery() {
    throw UnimplementedError('startDiscovery() has not been implemented.');
  }

  /// Stops discovering devices.
  Future<void> stopDiscovery() {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  /// Host creates a room with the selected device identifiers (e.g., usernames or network IPs).
  Future<void> createRoom(List<String> deviceIds) {
    throw UnimplementedError('createRoom() has not been implemented.');
  }

  /// Send a message to the room.
  Future<void> sendMessage(String message) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  /// Stream of discovered devices. Contains the username or device ID.
  Stream<String> get discoveryEvents {
    throw UnimplementedError('discoveryEvents has not been implemented.');
  }

  /// Stream of incoming room messages and status changes.
  Stream<Map<String, dynamic>> get roomEvents {
    throw UnimplementedError('roomEvents has not been implemented.');
  }
}
