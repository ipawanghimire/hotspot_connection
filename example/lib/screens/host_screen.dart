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
  final List<Peer> _discoveredDevices = [];
  final List<String> _selectedDeviceIds = [];
  final _hostNameController = TextEditingController(text: 'Host');
  StreamSubscription<Peer>? _discoverySub;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    await _hotspotConnectionPlugin.startDiscovery();
    _discoverySub = _hotspotConnectionPlugin.discoveryEvents.listen((peer) {
      if (!_discoveredDevices.any((d) => d.id == peer.id)) {
        setState(() {
          _discoveredDevices.add(peer);
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
    if (_selectedDeviceIds.isEmpty) return;
    final hostName = _hostNameController.text.trim().isEmpty
        ? 'Host'
        : _hostNameController.text.trim();
    final result = await _hotspotConnectionPlugin.createRoom(
      _selectedDeviceIds,
    );
    if (!mounted || !result.isSuccess) {
      // Example: Handle creation failure if list of connected is empty
      return;
    }

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
                final isSelected = _selectedDeviceIds.contains(device.id);
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text('ID: ${device.id}'),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDeviceIds.remove(device.id);
                      } else {
                        _selectedDeviceIds.add(device.id);
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
              onPressed: _selectedDeviceIds.isNotEmpty ? _createRoom : null,
              child: const Text('Create Room with Selected'),
            ),
          ),
        ],
      ),
    );
  }
}
