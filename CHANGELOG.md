## 1.0.0

* Major Refactor: Introduced strongly-typed API architecture using Domain models (`Peer`, `RoomEvent`, `RoomResult`).
* Native Overhaul: iOS and Android updated to handle precise TXT record Peer UUID generation, significantly improving connection reliability.
* Breaking Change: `createRoom` now accepts and returns `RoomResult` indicating connection success instead of mapping dynamic lists.
* Breaking Change: Streams now emit precise Events (`PeerJoinedEvent`, `PeerLeftEvent`, `MessageReceivedEvent`) rather than generic `Map<String, dynamic>`.

## 0.0.1

* Initial Open Source release.
