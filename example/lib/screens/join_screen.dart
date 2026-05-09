import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hotspot_connection/hotspot_connection.dart';
import 'chat_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _hotspotConnectionPlugin = HotspotConnection();
  final _nameController = TextEditingController();
  bool _isBroadcasting = false;
  StreamSubscription? _roomSub;

  @override
  void dispose() {
    _nameController.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  void _startBroadcasting() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await _hotspotConnectionPlugin.startBroadcasting(name);
    setState(() {
      _isBroadcasting = true;
    });

    // Listen for room creation/connection from host
    _roomSub = _hotspotConnectionPlugin.roomEvents.listen((event) {
      if (event['type'] == 'connected') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              isHost: false,
              plugin: _hotspotConnectionPlugin,
              username: name,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isBroadcasting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Waiting for host to invite you...'),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startBroadcasting,
                    child: const Text('Start Broadcasting'),
                  ),
                ],
              ),
      ),
    );
  }
}
