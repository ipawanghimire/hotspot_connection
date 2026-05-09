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
      createRoom(deviceIds: deviceIds)
      result(nil)
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
      listener?.service = NWListener.Service(name: username, type: serviceType)
      
      listener?.newConnectionHandler = { [weak self] newConnection in
        self?.setupConnection(newConnection)
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
          DispatchQueue.main.async {
            self?.discoveryEventSink?(name)
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

  func createRoom(deviceIds: [String]) {
    for deviceId in deviceIds {
      if let endpoint = discoveredEndpoints[deviceId] {
        let connection = NWConnection(to: endpoint, using: .tcp)
        setupConnection(connection)
        connection.start(queue: .main)
      }
    }
  }

  func setupConnection(_ connection: NWConnection) {
    activeConnections.append(connection)
    
    connection.stateUpdateHandler = { [weak self] state in
      switch state {
      case .ready:
        DispatchQueue.main.async {
          self?.roomEventSink?(["type": "connected"])
        }
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
    // Read up to newline, just like Android's BufferedReader.readLine()
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
      if let data = data, !data.isEmpty {
          var stringMessage = String(decoding: data, as: UTF8.self)
          // Trim newline added by PrintWriter in Android
          stringMessage = stringMessage.trimmingCharacters(in: .whitespacesAndNewlines)
          if !stringMessage.isEmpty {
              DispatchQueue.main.async {
                  self?.roomEventSink?(["type": "message", "data": stringMessage])
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
    // Mimic Android PrintWriter.println which adds newline
    let data = (message + "\n").data(using: .utf8) ?? Data()
    for connection in activeConnections {
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send error: \(error)")
            }
        }))
    }
  }
}
