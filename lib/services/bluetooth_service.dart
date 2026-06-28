import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BluetoothConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class ShelfBluetoothService extends ChangeNotifier {
  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  String _statusMessage = '蓝牙未连接';
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  BluetoothConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  BluetoothDevice? get device => _device;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  bool get isConnected => _status == BluetoothConnectionStatus.connected;

  Future<void> startScan() async {
    if (!(await FlutterBluePlus.isSupported)) {
      _setStatus(BluetoothConnectionStatus.error, '该设备不支持蓝牙');
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _setStatus(BluetoothConnectionStatus.error, '请打开设备蓝牙开关');
      return;
    }

    await stopScan();
    _scanResults = [];
    _setStatus(BluetoothConnectionStatus.scanning, '查找设备中...');

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    _device = device;
    _setStatus(
      BluetoothConnectionStatus.connecting,
      '正在连接 ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}...',
    );

    try {
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 12),
      );
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _writeCharacteristic = null;
          _setStatus(BluetoothConnectionStatus.disconnected, '蓝牙未连接');
        }
      });

      await _discoverWritableCharacteristic(device);
      _setStatus(
        BluetoothConnectionStatus.connected,
        'Connected to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}',
      );
    } catch (error) {
      _device = null;
      _setStatus(BluetoothConnectionStatus.error, '蓝牙连接失败: $error');
    }
  }

  Future<void> disconnect() async {
    final device = _device;
    _writeCharacteristic = null;
    if (device != null) {
      await device.disconnect();
    }
    _device = null;
    _setStatus(BluetoothConnectionStatus.disconnected, '蓝牙未连接');
  }

  Future<bool> sendString(String payload) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      _setStatus(BluetoothConnectionStatus.error, '未找到可写入的蓝牙特征');
      return false;
    }

    try {
      final bytes = utf8.encode(payload);
      await characteristic.write(bytes, withoutResponse: false);
      return true;
    } catch (error) {
      _setStatus(BluetoothConnectionStatus.error, '未能发送指令: $error');
      return false;
    }
  }

  Future<void> _discoverWritableCharacteristic(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          _writeCharacteristic = characteristic;
          return;
        }
      }
    }
  }

  void _setStatus(BluetoothConnectionStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
