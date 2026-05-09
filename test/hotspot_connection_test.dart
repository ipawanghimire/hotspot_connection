// import 'package:flutter_test/flutter_test.dart';
// import 'package:hotspot_connection/hotspot_connection.dart';
// import 'package:hotspot_connection/hotspot_connection_platform_interface.dart';
// import 'package:hotspot_connection/hotspot_connection_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockHotspotConnectionPlatform
//     with MockPlatformInterfaceMixin
//     implements HotspotConnectionPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final HotspotConnectionPlatform initialPlatform = HotspotConnectionPlatform.instance;

//   test('$MethodChannelHotspotConnection is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelHotspotConnection>());
//   });

//   test('getPlatformVersion', () async {
//     HotspotConnection hotspotConnectionPlugin = HotspotConnection();
//     MockHotspotConnectionPlatform fakePlatform = MockHotspotConnectionPlatform();
//     HotspotConnectionPlatform.instance = fakePlatform;

//     expect(await hotspotConnectionPlugin.getPlatformVersion(), '42');
//   });
// }
