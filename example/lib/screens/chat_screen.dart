import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hotspot_connection/hotspot_connection.dart';

class ChatScreen extends StatefulWidget {
  final bool isHost;
  final HotspotConnection plugin;
  final String username;

  const ChatScreen({
    super.key,
    required this.isHost,
    required this.plugin,
    required this.username,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final List<String> _messages = [];
  StreamSubscription<RoomEvent>? _roomSub;

  @override
  void initState() {
    super.initState();
    _roomSub = widget.plugin.roomEvents.listen((event) {
      setState(() {
        if (event is MessageReceivedEvent) {
          _messages.add(event.message);
        } else if (event is PeerLeftEvent) {
          _messages.add('--- ${event.peerId} disconnected ---');
        } else if (event is PeerJoinedEvent) {
          _messages.add('--- ${event.peer.name} joined ---');
        }
      });
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final formattedMessage = '${widget.username}: $text';
    await widget.plugin.sendMessage(formattedMessage);
    setState(() {
      _messages.add(formattedMessage);
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Room (Host)' : 'Room (Guest)'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
