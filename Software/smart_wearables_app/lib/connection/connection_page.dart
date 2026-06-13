import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:smart_wearables_app/app_shell_page.dart';
import 'package:smart_wearables_app/connection/stream.dart';
import 'package:smart_wearables_app/utils/head_cursor_controller.dart';

Uuid serviceUuid = Uuid.parse("49535343-FE7D-4AE5-8FA9-9FAFD205E455");
Uuid characteristicUuid =
    Uuid.parse("49535343-1E4D-4BD9-BA61-23C647249616");
Uuid characteristicUuidTX =
    Uuid.parse("49535343-8841-43F4-A8D4-ECBE34729BB3");

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key, required this.title});

  final String title;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final String bleDeviceNameFilter = "SW";

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<DiscoveredDevice> scanStream;
  late Stream<ConnectionStateUpdate> currentConnectionStream;
  late StreamSubscription<ConnectionStateUpdate> connection;

  StreamSubscription<List<int>>? rxSubscription;
  StreamSubscription<dynamic>? txSubscription;

  late QualifiedCharacteristic _rxCharacteristic;
  late QualifiedCharacteristic _txCharacteristic;

  List<DiscoveredDevice> foundBleDevices = [];
  List<DiscoveredDevice> foundBleDevicesFiltered = [];

  bool permGranted = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool appOpened = false;

  final MyStream incomingBLEStream = MyStream();
  final HeadCursorController headCursorController = HeadCursorController();

  void refreshScreen() {
    if (mounted) setState(() {});
  }

  Future<void> _sendStartStreamingCommand() async {
    if (!connected) return;

    for (int i = 0; i < 5; i++) {
      try {
        await flutterReactiveBle.writeCharacteristicWithoutResponse(
          _txCharacteristic,
          value: [83], // ASCII 'S'
        );
        debugPrint("Sent BLE command: S attempt ${i + 1}");
      } catch (e) {
        debugPrint("ERROR sending S attempt ${i + 1}: $e");
      }

      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _sendStopStreamingCommand() async {
    try {
      await flutterReactiveBle.writeCharacteristicWithoutResponse(
        _txCharacteristic,
        value: [80], // ASCII 'P'
      );
      debugPrint("Sent BLE command: P");
    } catch (e) {
      debugPrint("ERROR sending stop streaming command: $e");
    }
  }

  Future<void> _showNoPermissionDialog() async => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Permissions Missing'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You have not granted the required permissions.'),
                Text(
                  'Location and Bluetooth permissions are mandatory for BLE to work.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Acknowledge'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

  void _askPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted &&
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted) {
      permGranted = true;

      if (!scanning) {
        _startScan();
      }
    } else {
      permGranted = false;
    }
  }

  void _stopScan() async {
    await scanStream.cancel();
    scanning = false;
    refreshScreen();
  }

  void _startScan() async {
    if (scanning) {
      _stopScan();
    }

    if (!permGranted) {
      await _showNoPermissionDialog();
      return;
    }

    foundBleDevices = [];
    foundBleDevicesFiltered = [];
    scanning = true;
    refreshScreen();

    scanStream = flutterReactiveBle.scanForDevices(withServices: []).listen(
      (device) {
        if (foundBleDevices.every((element) => element.id != device.id)) {
          foundBleDevices.add(device);

          if (device.name.contains(bleDeviceNameFilter)) {
            foundBleDevicesFiltered.add(device);
          }

          refreshScreen();
        }
      },
      onError: (Object error) {
        debugPrint("ERROR during scan: $error \n");
        refreshScreen();
      },
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (scanning) {
        _stopScan();
      }
    });
  }

  void _startConnection(int index) async {
    if (scanning) {
      await scanStream.cancel();
      scanning = false;
    }

    if (connected) return;

    setState(() {
      connecting = true;
    });

    currentConnectionStream = flutterReactiveBle.connectToDevice(
      id: foundBleDevicesFiltered[index].id,
      connectionTimeout: const Duration(seconds: 5),
    );

    connection = currentConnectionStream.listen(
      (event) {
        final String id = event.deviceId.toString();

        switch (event.connectionState) {
          case DeviceConnectionState.connecting:
            connectingProcedure(id);
            break;

          case DeviceConnectionState.connected:
            connectionProcedure(id, event);
            break;

          case DeviceConnectionState.disconnected:
            disconnectionProcedure(id);
            break;

          default:
            break;
        }

        refreshScreen();
      },
      onError: (Object error) {
        connecting = false;
        connected = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection failed!"),
          ),
        );

        debugPrint("ERROR during connection: $error \n");

        _startScan();
        refreshScreen();
      },
    );
  }

  void connectingProcedure(String id) {
    connected = false;
    connecting = true;
    debugPrint("Connecting to $id...\n");
  }

  void connectionProcedure(String id, ConnectionStateUpdate event) {
    connected = true;
    connecting = false;
    debugPrint("Connected to $id\n");

    _rxCharacteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: event.deviceId,
    );

    _txCharacteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: characteristicUuidTX,
      deviceId: event.deviceId,
    );

    const int fixedPacketLength = 20;
    List<int> packetBuffer = [];

    rxSubscription =
        flutterReactiveBle.subscribeToCharacteristic(_rxCharacteristic).listen(
      (packet) {
        packetBuffer.addAll(packet);

        final int numPacketsReceived =
            (packetBuffer.length / fixedPacketLength).floor();

        for (int i = 0; i < numPacketsReceived; i++) {
          final List<int> data = packetBuffer.sublist(0, fixedPacketLength);
          packetBuffer.removeRange(0, fixedPacketLength);

          if (data[0] == 123 && data[fixedPacketLength - 1] == 125) {
            incomingBLEStream.setNum(data);
            headCursorController.parsePacket(data);
          }
        }
      },
      onError: (dynamic error) {
        debugPrint("ERROR during RX listen: ${error.toString()}\n");
      },
    );

    txSubscription = incomingBLEStream.controllerSend.stream.listen((event) {
      flutterReactiveBle.writeCharacteristicWithoutResponse(
        _txCharacteristic,
        value: event,
      );
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _sendStartStreamingCommand();
    });

    _openAppShell();
  }

  void _openAppShell() {
    if (!mounted || appOpened) return;

    appOpened = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppShellPage(
          stream: incomingBLEStream,
          cursorController: headCursorController,
        ),
      ),
    ).whenComplete(() {
      appOpened = false;

      if (connected) {
        forceDisconnection();
      }
    });
  }

  void disconnectionProcedure(String id) {
    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Disconnected!"),
        ),
      );
    }

    connected = false;
    connecting = false;
    appOpened = false;

    debugPrint("Disconnected from $id\n");

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  void forceDisconnection() async {
    if (connected) {
      await _sendStopStreamingCommand();

      await rxSubscription?.cancel();
      await txSubscription?.cancel();
      await connection.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Disconnected!"),
        ),
      );

      appOpened = false;

      _startScan();

      setState(() {
        connected = false;
        connecting = false;
      });
    }
  }

  @override
  void dispose() {
    if (scanning) {
      scanStream.cancel();
    }

    if (connected) {
      _sendStopStreamingCommand();
      connection.cancel();
    }

    rxSubscription?.cancel();
    txSubscription?.cancel();

    headCursorController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color darkText = const Color(0xFF3E3328);
    final Color beige = const Color(0xFFEADDCB);
    final Color lightBeige = const Color(0xFFFFFBF5);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7F1E8),
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              _startScan();
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightBeige,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.watch,
                        size: 44,
                        color: darkText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Smart Wearables',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        connected
                            ? 'Device connected'
                            : scanning
                                ? 'Searching for devices...'
                                : 'Select your wearable device to start.',
                        style: TextStyle(
                          fontSize: 16,
                          color: darkText.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: beige,
                            foregroundColor: darkText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: connecting ? null : _startScan,
                          icon: Icon(scanning ? Icons.sync : Icons.search),
                          label: Text(scanning ? 'Scanning...' : 'Scan again'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Available devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 12),
                if (foundBleDevicesFiltered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightBeige,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      scanning
                          ? 'No device found yet...'
                          : 'No device available. Pull down or press Scan again.',
                      style: TextStyle(
                        color: darkText.withOpacity(0.7),
                      ),
                    ),
                  )
                else
                  ...foundBleDevicesFiltered.asMap().entries.map(
                    (entry) {
                      final int index = entry.key;
                      final device = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: beige,
                            child: Icon(
                              Icons.bluetooth,
                              color: darkText,
                            ),
                          ),
                          title: Text(
                            device.name.isEmpty ? 'Unknown device' : device.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          subtitle: Text(device.id),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (!connecting) {
                              _startConnection(index);
                            }
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        if (connecting)
          const Opacity(
            opacity: 0.45,
            child: ModalBarrier(
              dismissible: false,
              color: Colors.black,
            ),
          ),
        if (connecting)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}