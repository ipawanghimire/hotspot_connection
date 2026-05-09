# hotspot_connection

A Flutter plugin for local network peer-to-peer (P2P) discovery and communication. This plugin uses native Network Service Discovery (NSD on Android, Bonjour/NetService on iOS) to find nearby devices on the same Wi-Fi network and establishes direct TCP socket connections for real-time data broadcasting and chat rooms.

## Features

- **Broadcast Presence**: Let other devices on the local network find you.
- **Discover Devices**: Scan the network for other devices broadcasting their presence.
- **Create P2P Rooms**: Host a session and connect with multiple selected devices.
- **Real-time Messaging**: Send and receive text payloads natively across connected TCP sockets.
- **Cross-Platform**: Supports both Android and iOS with native APIs.

## Platform Setup

### Android

Add the following permissions to your `android/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### iOS

Add the following keys to your `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>We need to discover nearby devices.</string>
<key>NSBonjourServices</key>
<array>
    <string>_hotspotchat._tcp</string>
</array>
```

## Usage

### 1. Initialize Plugin

```dart
import 'package:hotspot_connection/hotspot_connection.dart';

final hotspot = HotspotConnection();
```

### 2. Joiner: Broadcast Presence

To allow the host to find you, start broadcasting your username:

```dart
await hotspot.startBroadcasting("John Doe");

// Listen for connection events when the host creates the room
hotspot.roomEvents.listen((event) {
  if (event['type'] == 'connected') {
    print("Joined the room!");
  }
});
```

### 3. Host: Discover Devices

Start looking for broadcasting devices:

```dart
await hotspot.startDiscovery();

// Listen to the discovery stream to see devices as they are found
hotspot.discoveryEvents.listen((device) {
  print("Found device: $device");
});
```

### 4. Host: Create a Room

Once you have collected the names of the discovered devices, select the ones you want to connect to:

```dart
await hotspot.stopDiscovery(); // Good practice to stop scanning before connecting
await hotspot.createRoom(["John Doe", "Jane Smith"]);
```

### 5. Send and Receive Messages

Once connected, both Host and Joiners can listen to and send messages:

**Listen for messages:**

```dart
hotspot.roomEvents.listen((event) {
  if (event['type'] == 'message') {
    print("Received: ${event['data']}");
  } else if (event['type'] == 'disconnected') {
    print("A user disconnected.");
  }
});
```

**Send a message:**

```dart
await hotspot.sendMessage("Hello everyone!");
```

## Example

Check the `example/` folder for a complete working chat application implementing host and join features.

### Screenshots

<p align="center">
  <img src="https://res.cloudinary.com/doeglj63f/image/upload/v1778339099/Screenshot_20260509-203733_iu8dem.png" width="250" hspace="10"/>
  <img src="https://res.cloudinary.com/doeglj63f/image/upload/v1778339099/Screenshot_20260509-203745_sgvp9h.png" width="250" hspace="10"/>
  <img src="https://res.cloudinary.com/doeglj63f/image/upload/v1778339098/Screenshot_20260509-203728_rwiegi.png" width="250" hspace="10"/>
</p>
