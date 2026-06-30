import 'dart:async';
import 'dart:math' as math;

import 'package:evi/config/bluetooth_config.dart';
import 'package:evi/utils/bluetooth_uuid.dart';
import 'package:evi/utils/modbus_crc16.dart';
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
  static const int _chunkSize = 20;
  static const Duration _interChunkDelay = Duration(milliseconds: 20);

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  String _statusMessage = '蓝牙未连接';
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  String _lastReceivedHex = '';
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  BluetoothConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic => _notifyCharacteristic;
  String get lastReceivedHex => _lastReceivedHex;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  bool get isConnected => _status == BluetoothConnectionStatus.connected;

  String? get writeCharacteristicLabel {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      return null;
    }
    return characteristic.uuid.str;
  }

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

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );
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

    final previousDevice = _device;
    _device = device;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _lastReceivedHex = '';
    _setStatus(
      BluetoothConnectionStatus.connecting,
      '正在连接 ${_deviceLabel(device)}...',
    );

    try {
      if (previousDevice != null &&
          previousDevice.remoteId != device.remoteId) {
        try {
          await previousDevice.disconnect();
        } catch (_) {
          // Ignore stale disconnect errors.
        }
        _connectionSubscription?.cancel();
        _notifySubscription?.cancel();
      }

      await device.connect(
        license: License.nonprofit,
        autoConnect: false,
        timeout: const Duration(seconds: 15),
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));

      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _clearCharacteristics();
          _setStatus(BluetoothConnectionStatus.disconnected, '蓝牙未连接');
        }
      });

      await _discoverCharacteristics(device);
      if (_writeCharacteristic == null) {
        throw StateError('未找到可写入的蓝牙特征');
      }

      await _enableNotify(_notifyCharacteristic);

      final name = _deviceLabel(device);
      final notifyLabel = _notifyCharacteristic?.uuid.str ?? 'none';
      _setStatus(
        BluetoothConnectionStatus.connected,
        '已连接 $name (写: ${writeCharacteristicLabel ?? 'unknown'}, 通知: $notifyLabel)',
      );
    } catch (error) {
      _device = null;
      _clearCharacteristics();
      _setStatus(BluetoothConnectionStatus.error, '蓝牙连接失败: $error');
    }
  }

  Future<void> disconnect() async {
    final device = _device;
    _clearCharacteristics();
    if (device != null) {
      await device.disconnect();
    }
    _device = null;
    _setStatus(BluetoothConnectionStatus.disconnected, '蓝牙未连接');
  }

  Future<bool> sendHexBytes(
    String hexPayload, {
    bool delayBeforeWrite = true,
  }) async {
    try {
      final bytes = ModbusCrc16.decodeHex(hexPayload);
      return sendBytes(bytes, delayBeforeWrite: delayBeforeWrite);
    } catch (error) {
      _setStatus(BluetoothConnectionStatus.error, '未能发送指令: $error');
      return false;
    }
  }

  /// Sends binary payloads in order, waiting [interval] between each item.
  Future<bool> sendBytesSequence(
    List<List<int>> payloads, {
    Duration interval = Duration.zero,
    bool delayBeforeFirst = true,
  }) async {
    for (var index = 0; index < payloads.length; index++) {
      if (index > 0 && interval > Duration.zero) {
        await Future<void>.delayed(interval);
      }

      final sent = await sendBytes(
        payloads[index],
        delayBeforeWrite: index == 0 && delayBeforeFirst,
      );
      if (!sent) {
        return false;
      }
    }
    return true;
  }

  /// Sends hex payloads in order, waiting [interval] between each item.
  Future<bool> sendHexSequence(
    List<String> hexPayloads, {
    Duration interval = Duration.zero,
    bool delayBeforeFirst = true,
  }) async {
    for (var index = 0; index < hexPayloads.length; index++) {
      if (index > 0 && interval > Duration.zero) {
        await Future<void>.delayed(interval);
      }

      final sent = await sendHexBytes(
        hexPayloads[index],
        delayBeforeWrite: index == 0 && delayBeforeFirst,
      );
      if (!sent) {
        return false;
      }
    }
    return true;
  }

  /// Decodes [bodyHex] to bytes, appends Modbus RTU CRC, and sends as binary.
  Future<bool> sendModbusRtuHexCommand(String bodyHex) async {
    final bytes = ModbusCrc16.buildBytesCommand(bodyHex);
    return sendBytes(bytes);
  }

  /// Sends [bytes] as one binary BLE write (matches DTU reference app).
  Future<bool> sendBytes(
    List<int> bytes, {
    bool delayBeforeWrite = true,
  }) async {
    if (_writeCharacteristic == null) {
      _setStatus(BluetoothConnectionStatus.error, '未找到可写入的蓝牙特征');
      return false;
    }

    if (bytes.isEmpty) {
      return true;
    }

    final characteristic = _writeCharacteristic!;

    try {
      if (delayBeforeWrite) {
        await Future<void>.delayed(BluetoothConfig.preWriteDelay);
      }
      await _writeBytes(characteristic, bytes);
      return true;
    } catch (error) {
      _setStatus(BluetoothConnectionStatus.error, '未能发送指令: $error');
      return false;
    }
  }

  Future<void> _writeBytes(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    if (await _trySingleWrite(characteristic, bytes)) {
      return;
    }

    for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
      final end = math.min(offset + _chunkSize, bytes.length);
      final chunk = bytes.sublist(offset, end);
      if (!await _trySingleWrite(characteristic, chunk)) {
        throw StateError('Unable to write ${chunk.length} byte(s) to device');
      }
      if (end < bytes.length) {
        await Future<void>.delayed(_interChunkDelay);
      }
    }
  }

  Future<bool> _trySingleWrite(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    if (characteristic.properties.write) {
      try {
        await characteristic.write(
          bytes,
          withoutResponse: false,
          allowLongWrite: true,
        );
        return true;
      } catch (error) {
        if (!_isInvalidAttributeLength(error)) {
          rethrow;
        }
      }
    }

    if (characteristic.properties.writeWithoutResponse) {
      try {
        await characteristic.write(
          bytes,
          withoutResponse: true,
        );
        return true;
      } catch (error) {
        if (!_isInvalidAttributeLength(error)) {
          rethrow;
        }
      }
    }

    return false;
  }

  bool _isInvalidAttributeLength(Object error) {
    if (error is FlutterBluePlusException) {
      if (error.code == 13) {
        return true;
      }
      final message = '${error.description} ${error.toString()}';
      if (message.contains('GATT_INVALID_ATTRIBUTE_LENGTH')) {
        return true;
      }
    }
    return error.toString().contains('GATT_INVALID_ATTRIBUTE_LENGTH') ||
        error.toString().contains('android-code: 13');
  }

  Future<void> _discoverCharacteristics(BluetoothDevice device) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;
    final writableFallbacks = <BluetoothCharacteristic>[];
    final notifyFallbacks = <BluetoothCharacteristic>[];

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str;

        if (BluetoothUuid.isWriteCharacteristic(uuid)) {
          writeChar = characteristic;
        } else if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          writableFallbacks.add(characteristic);
        }

        if (BluetoothUuid.isNotifyCharacteristic(uuid)) {
          notifyChar = characteristic;
        } else if (characteristic.properties.notify ||
            characteristic.properties.indicate) {
          notifyFallbacks.add(characteristic);
        }
      }
    }

    writeChar ??= _pickFallbackWrite(writableFallbacks);
    notifyChar ??= notifyFallbacks.isNotEmpty ? notifyFallbacks.first : null;

    _writeCharacteristic = writeChar;
    _notifyCharacteristic = notifyChar;
  }

  BluetoothCharacteristic? _pickFallbackWrite(
    List<BluetoothCharacteristic> candidates,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    for (final candidate in candidates) {
      if (BluetoothUuid.matchesFallbackWrite(candidate.uuid.str)) {
        return candidate;
      }
    }

    return candidates.first;
  }

  Future<void> _enableNotify(BluetoothCharacteristic? characteristic) async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;

    if (characteristic == null) {
      return;
    }

    try {
      await characteristic.setNotifyValue(true);

      try {
        final cccd = characteristic.descriptors.firstWhere(
          (descriptor) => BluetoothUuid.matches(
            descriptor.uuid.str,
            BluetoothConfig.cccdDescriptorUuid,
            '2902',
          ),
        );
        await cccd.write([0x01, 0x00]);
      } catch (_) {
        // Some stacks enable notify without an explicit CCCD write.
      }

      _notifySubscription = characteristic.lastValueStream.listen((data) {
        if (data.isEmpty) {
          return;
        }
        _lastReceivedHex = data
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        notifyListeners();
      });
    } catch (error) {
      debugPrint('Failed to enable BLE notify: $error');
    }
  }

  void _clearCharacteristics() {
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _lastReceivedHex = '';
    _notifySubscription?.cancel();
    _notifySubscription = null;
  }

  String _deviceLabel(BluetoothDevice device) {
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    if (device.advName.isNotEmpty) {
      return device.advName;
    }
    return device.remoteId.str;
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
    _notifySubscription?.cancel();
    super.dispose();
  }
}
