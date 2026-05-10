import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hotspot_connection_platform_interface.dart';
import 'models/peer.dart';
import 'models/room_event.dart';
import 'models/room_result.dart';

class MethodChannelHotspotConnection extends HotspotConnectionPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('hotspot_connection');
  
  @visibleForTesting
  final discoveryEventChannel = const EventChannel('hotspot_connection/discovery');

  @visibleForTesting
  final roomEventChannel = const EventChannel('hotspot_connection/room');

  late final Stream<Peer> _discoveryEvents = discoveryEventChannel
      .receiveBroadcastStream()
      .map((event) => Peer.fromMap(Map<dynamic, dynamic>.from(event)));

  late final Stream<RoomEvent> _roomEvents = roomEventChannel
      .receiveBroadcastStream()
      .map((event) {
        final map = Map<String, dynamic>.from(event);
        final type = map['type'];
        
        if (type == 'connected') {
          final peerMap = map['peer'] as Map?;
          final peer = peerMap != null ? Peer.fromMap(peerMap) : Peer(id: map['peerId'] ?? 'unknown', name: 'Unknown');
          return PeerJoinedEvent(peer);
        } else if (type == 'disconnected') {
          return PeerLeftEvent(map['peerId'] ?? 'unknown');
        } else if (type == 'message') {
          return MessageReceivedEvent(
             peerId: map['peerId'] ?? 'unknown',
             message: map['data'] ?? '',
          );
        }
        throw Exception('Unknown room event type: $type');
      });

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> startBroadcasting(String username, String peerId) async {
    await methodChannel.invokeMethod('startBroadcasting', {'username': username, 'peerId': peerId});
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
  Future<RoomResult> createRoom(List<String> deviceIds) async {
    final result = await methodChannel.invokeMethod('createRoom', {'deviceIds': deviceIds});
    final map = Map<String, dynamic>.from(result ?? {});
    
    final connected = (map['connected'] as List?)?.map((e) => Peer.fromMap(e)).toList() ?? [];
    final failed = (map['failed'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    return RoomResult(connectedPeers: connected, failedPeerIds: failed);
  }

  @override
  Future<void> sendMessage(String message) async {
    await methodChannel.invokeMethod('sendMessage', {'message': message});
  }

  @override
  Stream<Peer> get discoveryEvents => _discoveryEvents;

  @override
  Stream<RoomEvent> get roomEvents => _roomEvents;
}
