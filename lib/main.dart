import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bluetooth App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // A list of scanned devices
  List<BluetoothDevice> devices = [];
  // The selected device
  BluetoothDevice? device;
  // The selected characteristic
  BluetoothCharacteristic? characteristic;
  // The data to send
  String data = "Hello";
  // A flag to indicate if scanning is in progress
  bool isScanning = false;
  // A flag to indicate if connected to a device
  bool isConnected = false;
  // A flag to indicate if sending data
  bool isSending = false;

  // A reference to the FlutterBlue instance
  FlutterBlue flutterBlue = FlutterBlue.instance;

  void startScan() async {
    setState(() {
      isScanning = true;
    });
    print("Scanning Starts.....");

    devices.clear();
 
      await flutterBlue.startScan(timeout: Duration(seconds: 30));
      print("Scanning Done......");
      print("showing in the list");
      flutterBlue.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devices.contains(result.device)) {
            devices.add(result.device);
          }
        }
        setState(() {});
      });

      print("stopping scanning to show result/");
      await flutterBlue.stopScan();
      setState(() {
        isScanning = false;
      });
    
  }

  void connectDevice(BluetoothDevice device) async {
    setState(() {
      isConnected = true;
    });

    print("connecting the device...");
    
    await device.connect();
    setState(() {
      this.device = device;
    });

    print("connected to ${device.name}");

    print('finally discovring the type of services it provides.');
    discoverServices();
  }

  void disConnectDevices() async {
    print("disconnecting the device.");
    await device?.disconnect();
    setState(() {
      device = null;
      characteristic = null;
      isConnected = false;
    });
    print("device disconnected.");
  }

  void discoverServices() async {
    List<BluetoothService> services = await device!.discoverServices();
    for (BluetoothService service in services) {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      for (BluetoothCharacteristic characteristic in characteristics) {
        // For simplicity, we assume that the first characteristic that has write and notify properties is the one we want
        if (characteristic.properties.write &&
            characteristic.properties.notify) {
          setState(() {
            this.characteristic = characteristic;
          });
          // Set up a listener for receiving notifications from the characteristic
          characteristic.value.listen((value) {
            print("Received: $value");
          });
          break;
        }
      }
    }
  }

  // A method to send data to a characteristic
  void sendData(int data) async {
    setState(() {
      isSending = true;
    });
    // Convert the data to a list of bytes
    List<int> bytes = [data];
    // Write the bytes to the characteristic
    await characteristic?.write(bytes);
    print("Sent: $bytes");
    setState(() {
      isSending = false;
    });
  }

  Widget buildButton(String label, int data) {
    return ElevatedButton(
      onPressed: isSending ? null : () => sendData(data),
      child: Text(label),
    );
  }

  Widget showConnectedPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Connected to ${device?.name}"),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildButton("1", 1),
              buildButton("2", 2),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildButton("3", 3),
              buildButton("4", 4),
            ],
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  isConnected = false;
                  disConnectDevices();
                });
              },
              child: Text("Back"))
        ],
      ),
    );
  }

  Widget buildScanDevices() {
    return Column(
      children: [
        ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? "Scanning" : "Scan Devices.")),
        Expanded(
            child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(devices[index].name),
                    subtitle: Text(devices[index].id.toString()),
                    onTap: () {
                      connectDevice(devices[index]);
                    },
                  );
                }))
      ],
    );
  }

  // Widget buildConnectDevices() {
  //   print("Connected to ${device?.name}");
  //   return Column(
  //     children: [
  //       Text("Connected to" +  device!.name),
  //       ElevatedButton(
  //           onPressed: () {
  //             setState(() {
  //               isConnected = false;
  //             });
  //           },
  //           child: Text("Disconnect")),
  //       TextField(
  //         decoration: InputDecoration(labelText: "Data to send"),
  //         onChanged: (value) {
  //           setState(() {
  //             data = value;
  //           });
  //         },
  //       ),
  //       ElevatedButton(
  //           onPressed: isSending ? null : null,
  //           child: Text(isSending ? "Sending" : "Send Data"))
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: isConnected ? showConnectedPage() : buildScanDevices(),
      ),
    ));
  }
}
