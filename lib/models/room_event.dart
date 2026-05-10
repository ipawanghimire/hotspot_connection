import 'peer.dart';

abstract class RoomEvent {}

class PeerJoinedEvent extends RoomEvent {
  final Peer peer;
  PeerJoinedEvent(this.peer);
}

class PeerLeftEvent extends RoomEvent {
  final String peerId;
  PeerLeftEvent(this.peerId);
}

class MessageReceivedEvent extends RoomEvent {
  final String peerId;
  final String message;

  MessageReceivedEvent({
    required this.peerId,
    required this.message,
  });
}
