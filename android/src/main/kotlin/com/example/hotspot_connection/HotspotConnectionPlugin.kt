package com.example.hotspot_connection

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.net.ServerSocket
import java.net.Socket
import java.io.PrintWriter
import java.io.BufferedReader
import java.io.InputStreamReader
import kotlin.concurrent.thread

class HotspotConnectionPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var methodChannel : MethodChannel
  private lateinit var discoveryEventChannel: EventChannel
  private lateinit var roomEventChannel: EventChannel

  private var discoveryEventSink: EventChannel.EventSink? = null
  private var roomEventSink: EventChannel.EventSink? = null

  private lateinit var context: Context
  private lateinit var nsdManager: NsdManager
  private val SERVICE_TYPE = "_hotspotchat._tcp."

  private var registrationListener: NsdManager.RegistrationListener? = null
  private var discoveryListener: NsdManager.DiscoveryListener? = null

  private var serverSocket: ServerSocket? = null
  private val activeSockets = mutableListOf<Socket>()
  private val mainHandler = Handler(Looper.getMainLooper())
  
  private val discoveredServices = mutableMapOf<String, NsdServiceInfo>()
  private val socketLock = Any() // Ensure thread-safety for active sockets

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager

    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "hotspot_connection")
    methodChannel.setMethodCallHandler(this)
    
    discoveryEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "hotspot_connection/discovery")
    discoveryEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            discoveryEventSink = events
        }
        override fun onCancel(arguments: Any?) {
            discoveryEventSink = null
        }
    })

    roomEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "hotspot_connection/room")
    roomEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            roomEventSink = events
        }
        override fun onCancel(arguments: Any?) {
            roomEventSink = null
        }
    })
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> { result.success("Android ${android.os.Build.VERSION.RELEASE}") }
      "startBroadcasting" -> {
        val username = call.argument<String>("username") ?: "Unknown"
        startBroadcasting(username)
        result.success(null)
      }
      "startDiscovery" -> {
        startDiscovery()
        result.success(null)
      }
      "stopDiscovery" -> {
        stopDiscovery()
        result.success(null)
      }
      "createRoom" -> {
        val deviceIds = call.argument<List<String>>("deviceIds") ?: emptyList()
        createRoom(deviceIds)
        result.success(null)
      }
      "sendMessage" -> {
        val message = call.argument<String>("message") ?: ""
        sendMessage(message)
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun startBroadcasting(username: String) {
    serverSocket = ServerSocket(0)
    val port = serverSocket!!.localPort

    thread {
        try {
            while (true) {
                val socket = serverSocket!!.accept()
                synchronized(socketLock) { activeSockets.add(socket) }
                mainHandler.post {
                    roomEventSink?.success(mapOf("type" to "connected"))
                }
                listenToSocket(socket)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    val serviceInfo = NsdServiceInfo().apply {
        serviceName = username
        serviceType = SERVICE_TYPE
        this.port = port
    }

    registrationListener = object : NsdManager.RegistrationListener {
        override fun onServiceRegistered(NsdServiceInfo: NsdServiceInfo) {}
        override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
        override fun onServiceUnregistered(arg0: NsdServiceInfo) {}
        override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
    }

    nsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener)
  }

  private fun startDiscovery() {
    discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onDiscoveryStarted(regType: String) {}
        override fun onServiceFound(service: NsdServiceInfo) {
            if (service.serviceType == SERVICE_TYPE) {
                nsdManager.resolveService(service, object : NsdManager.ResolveListener {
                    override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
                    override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                        val name = serviceInfo.serviceName
                        discoveredServices[name] = serviceInfo
                        mainHandler.post {
                            discoveryEventSink?.success(name)
                        }
                    }
                })
            }
        }
        override fun onServiceLost(service: NsdServiceInfo) {}
        override fun onDiscoveryStopped(serviceType: String) {}
        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
            nsdManager.stopServiceDiscovery(this)
        }
        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
            nsdManager.stopServiceDiscovery(this)
        }
    }

    nsdManager.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
  }

  private fun stopDiscovery() {
    discoveryListener?.let {
        try { nsdManager.stopServiceDiscovery(it) } catch (e: Exception) {}
        discoveryListener = null
    }
  }

  private fun createRoom(deviceIds: List<String>) {
    deviceIds.forEach { deviceId ->
        val service = discoveredServices[deviceId]
        if (service != null && service.host != null) {
            thread {
                try {
                    val socket = Socket(service.host, service.port)
                    synchronized(socketLock) { activeSockets.add(socket) }
                    mainHandler.post {
                        roomEventSink?.success(mapOf("type" to "connected"))
                    }
                    listenToSocket(socket)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
  }

  private fun listenToSocket(socket: Socket) {
    thread {
        try {
            val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
            while (true) {
                val message = reader.readLine() ?: break
                
                mainHandler.post {
                    roomEventSink?.success(mapOf("type" to "message", "data" to message))
                }

                // If HOST receives a message, relay it to all OTHER active clients
                // to support full chat room functionality
                val others = synchronized(socketLock) { activeSockets.filter { it != socket } }
                if (others.isNotEmpty()) {
                    others.forEach { otherSocket ->
                        thread {
                            try {
                                val out = PrintWriter(otherSocket.getOutputStream(), true)
                                out.println(message)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            mainHandler.post {
                roomEventSink?.success(mapOf("type" to "disconnected"))
            }
            synchronized(socketLock) { activeSockets.remove(socket) }
        }
    }
  }

  private fun sendMessage(message: String) {
    val sockets = synchronized(socketLock) { activeSockets.toList() }
    sockets.forEach { socket ->
        thread {
            try {
                val out = PrintWriter(socket.getOutputStream(), true)
                out.println(message)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    discoveryEventChannel.setStreamHandler(null)
    roomEventChannel.setStreamHandler(null)
    try { registrationListener?.let { nsdManager.unregisterService(it) } } catch (e: Exception) {}
    stopDiscovery()
    try { serverSocket?.close() } catch (e: Exception) {}
    synchronized(socketLock) {
        activeSockets.forEach { try { it.close() } catch (e: Exception) {} }
        activeSockets.clear()
    }
  }
}
