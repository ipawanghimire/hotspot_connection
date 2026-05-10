import Flutter
import UIKit
import Network

class DiscoveryStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: HotspotConnectionPlugin?
    init(plugin: HotspotConnectionPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.discoveryEventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.discoveryEventSink = nil
        return nil
    }
}

class RoomStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: HotspotConnectionPlugin?
    init(plugin: HotspotConnectionPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.roomEventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.roomEventSink = nil
        return nil
    }
}

public class HotspotConnectionPlugin: NSObject, FlutterPlugin {
  var discoveryEventSink: FlutterEventSink?
  var roomEventSink: FlutterEventSink?

  let serviceType = "_hotspotchat._tcp"
  let serviceDomain = "local."

  var listener: NWListener?
  var browser: NWBrowser?
  var activeConnections: [NWConnection] = []
  var discoveredEndpoints: [String: NWEndpoint] = [:]
  var discoveredNames: [String: String] = [:] // id -> name

  var myPeerId: String = ""

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "hotspot_connection", binaryMessenger: registrar.messenger())
    let instance = HotspotConnectionPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    
    let discoveryEventChannel = FlutterEventChannel(name: "hotspot_connection/discovery", binaryMessenger: registrar.messenger())
    discoveryEventChannel.setStreamHandler(DiscoveryStreamHandler(plugin: instance))
    
    let roomEventChannel = FlutterEventChannel(name: "hotspot_connection/room", binaryMessenger: registrar.messenger())
    roomEventChannel.setStreamHandler(RoomStreamHandler(plugin: instance))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "startBroadcasting":
      let args = call.arguments as? [String: Any]
      let username = args?["username"] as? String ?? "Unknown"
      myPeerId = args?["peerId"] as? String ?? "peer_\(Date().timeIntervalSince1970)"
      startBroadcasting(username: username)
      result(nil)
    case "startDiscovery":
      startDiscovery()
      result(nil)
    case "stopDiscovery":
      stopDiscovery()
      result(nil)
    case "createRoom":
      let args = call.arguments as? [String: Any]
      let deviceIds = args?["deviceIds"] as? [String] ?? []
      createRoom(deviceIds: deviceIds, result: result)
    case "sendMessage":
      let args = call.arguments as? [String: Any]
      let message = args?["message"] as? String ?? ""
      sendMessage(message: message)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func startBroadcasting(username: String) {
    do {
      listener = try NWListener(using: .tcp)
      
      // TXT Record equivalent in NWListener
      let txtRecord = NWTXTRecord()
      // Note: Network framework truncates some properties over bonjour if the name doesn't match exactly initially, 
      // but adding txt records binds perfectly.
      listener?.service = NWListener.Service(name: myPeerId, type: serviceType, txtRecord: txtRecord)
      // Custom attributes aren't always explicitly respected in NWBrowser .bonjour unless encoded directly into the record, 
      // so for consistency we encode them as JSON or specific text bindings in more advanced impls. For now, 
      // the `NWListener` uses `myPeerId` as its explicit name to guarantee connection reliability.
      
      listener?.newConnectionHandler = { [weak self] newConnection in
        self?.setupConnection(newConnection)
        DispatchQueue.main.async {
            self?.roomEventSink?(["type": "connected", "peerId": "unknown"])
        }
      }
      
      listener?.start(queue: .main)
    } catch {
      print("Failed to start listener: \(error)")
    }
  }

  func startDiscovery() {
    let parameters = NWParameters.tcp
    parameters.includePeerToPeer = true
    
    browser = NWBrowser(for: .bonjour(type: serviceType, domain: serviceDomain), using: parameters)
    
    browser?.browseResultsChangedHandler = { [weak self] results, changes in
      for result in results {
        if case let .service(name, _, _, _) = result.endpoint {
          self?.discoveredEndpoints[name] = result.endpoint
          // In a prod iOS app you map TXT records from Metadata here to extract `name`. For now defaulting.
          let peerName = "Unknown"
          self?.discoveredNames[name] = peerName
          
          DispatchQueue.main.async {
            self?.discoveryEventSink?([
                "id": name,
                "name": peerName, // Extracted from TXT in a perfect world
                "host": nil // iOS obscures explicit IPs in modern Network framework intentionally
            ])
          }
        }
      }
    }
    
    browser?.start(queue: .main)
  }
  
  func stopDiscovery() {
      browser?.cancel()
      browser = nil
  }

  func createRoom(deviceIds: [String], result: @escaping FlutterResult) {
    var connected: [[String: String]] = []
    var failed: [String] = []
    
    let group = DispatchGroup()

    for deviceId in deviceIds {
      group.enter()
      if let endpoint = discoveredEndpoints[deviceId] {
        let connection = NWConnection(to: endpoint, using: .tcp)
        activeConnections.append(connection)
        
        connection.stateUpdateHandler = { [weak self, weak connection] state in
          switch state {
          case .ready:
            DispatchQueue.main.async {
              let pName = self?.discoveredNames[deviceId] ?? "Unknown"
              let peerInfo = ["id": deviceId, "name": pName]
              self?.roomEventSink?(["type": "connected", "peer": peerInfo])
              connected.append(peerInfo)
              group.leave()
            }
            if let c = connection {
                self?.receiveLoop(on: c)
            }
            connection?.stateUpdateHandler = nil // Only trigger group logic on initial connect
          case .failed(_), .cancelled:
            DispatchQueue.main.async {
              failed.append(deviceId)
              group.leave()
            }
            if let c = connection {
                 self?.activeConnections.removeAll { $0 === c }
            }
            connection?.stateUpdateHandler = nil
          default:
            break
          }
        }
        connection.start(queue: .main)
      } else {
          failed.append(deviceId)
          group.leave()
      }
    }
    
    group.notify(queue: .main) {
        result([
            "connected": connected,
            "failed": failed
        ])
    }
  }

  func setupConnection(_ connection: NWConnection) {
    activeConnections.append(connection)
    
    connection.stateUpdateHandler = { [weak self] state in
      switch state {
      case .ready:
        self?.receiveLoop(on: connection)
      case .failed(_), .cancelled:
        DispatchQueue.main.async {
          self?.roomEventSink?(["type": "disconnected"])
        }
        self?.activeConnections.removeAll { $0 === connection }
      default:
        break
      }
    }
    connection.start(queue: .main)
  }

  func receiveLoop(on connection: NWConnection) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
      if let data = data, !data.isEmpty, let self = self {
          if let stringMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
              if let dict = self.convertToDictionary(text: stringMessage) {
                  DispatchQueue.main.async {
                      self.roomEventSink?(dict)
                  }
                  
                  // RELAY
                  let others = self.activeConnections.filter { $0 !== connection }
                  for other in others {
                      let outData = (stringMessage + "\n").data(using: .utf8) ?? Data()
                      other.send(content: outData, completion: .contentProcessed({ _ in }))
                  }
              }
          }
      }
      if isComplete || error != nil {
          connection.cancel()
      } else {
          self?.receiveLoop(on: connection)
      }
    }
  }

  func sendMessage(message: String) {
    let dict = ["type": "message", "peerId": myPeerId, "data": message]
    if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let data = (jsonString + "\n").data(using: .utf8) ?? Data()
            for connection in activeConnections {
                connection.send(content: data, completion: .contentProcessed({ _ in }))
            }
        }
    }
  }

  func convertToDictionary(text: String) -> [String: Any]? {
      if let data = text.data(using: .utf8) {
          do {
              return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
          } catch {
              print(error.localizedDescription)
          }
      }
      return nil
  }
}
