import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hotspot_connection/hotspot_connection.dart';
import 'chat_screen.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final _hotspotConnectionPlugin = HotspotConnection();
  final List<String> _discoveredDevices = [];
  final List<String> _selectedDevices = [];
  final _hostNameController = TextEditingController(text: 'Host');
  StreamSubscription? _discoverySub;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    await _hotspotConnectionPlugin.startDiscovery();
    _discoverySub = _hotspotConnectionPlugin.discoveryEvents.listen((device) {
      if (!_discoveredDevices.contains(device)) {
        setState(() {
          _discoveredDevices.add(device);
        });
      }
    });
  }

  @override
  void dispose() {
    _hostNameController.dispose();
    _discoverySub?.cancel();
    _hotspotConnectionPlugin.stopDiscovery();
    super.dispose();
  }

  void _createRoom() async {
    if (_selectedDevices.isEmpty) return;
    final hostName = _hostNameController.text.trim().isEmpty
        ? 'Host'
        : _hostNameController.text.trim();
    await _hotspotConnectionPlugin.createRoom(_selectedDevices);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          isHost: true,
          plugin: _hotspotConnectionPlugin,
          username: hostName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Searching for users...')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _hostNameController,
              decoration: const InputDecoration(
                labelText: 'Your Username (Host)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                final isSelected = _selectedDevices.contains(device);
                return ListTile(
                  title: Text(device),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDevices.remove(device);
                      } else {
                        _selectedDevices.add(device);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedDevices.isNotEmpty ? _createRoom : null,
              child: const Text('Create Room with Selected'),
            ),
          ),
        ],
      ),
    );
  }
}
