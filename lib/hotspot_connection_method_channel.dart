import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hotspot_connection_platform_interface.dart';

/// An implementation of [HotspotConnectionPlatform] that uses method channels.
class MethodChannelHotspotConnection extends HotspotConnectionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hotspot_connection');

  /// The event channel for discovery events.
  @visibleForTesting
  final discoveryEventChannel = const EventChannel(
    'hotspot_connection/discovery',
  );

  /// The event channel for room events.
  @visibleForTesting
  final roomEventChannel = const EventChannel('hotspot_connection/room');

  // Cache the streams to prevent Native EventSink cancellations when switching Flutter screens
  late final Stream<String> _discoveryEvents = discoveryEventChannel
      .receiveBroadcastStream()
      .map((event) => event.toString());
  late final Stream<Map<String, dynamic>> _roomEvents = roomEventChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event));

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> startBroadcasting(String username) async {
    await methodChannel.invokeMethod('startBroadcasting', {
      'username': username,
    });
  }

  @override
  Future<void> startDiscovery() async {
    await methodChannel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await methodChannel.invokeMethod('stopDiscovery');
  }

  @override
  Future<void> createRoom(List<String> deviceIds) async {
    await methodChannel.invokeMethod('createRoom', {'deviceIds': deviceIds});
  }

  @override
  Future<void> sendMessage(String message) async {
    await methodChannel.invokeMethod('sendMessage', {'message': message});
  }

  @override
  Stream<String> get discoveryEvents => _discoveryEvents;

  @override
  Stream<Map<String, dynamic>> get roomEvents => _roomEvents;
}
