/// BLE characteristics for DTU02CE / shelf modules.
abstract final class BluetoothConfig {
  /// DTU02CE write characteristic (full UUID).
  static const writeCharacteristicUuidFull =
      '00001001-0000-1000-8000-00805f9b34fb';

  /// DTU02CE notify characteristic (full UUID).
  static const notifyCharacteristicUuidFull =
      '00001002-0000-1000-8000-00805f9b34fb';

  static const writeCharacteristicShort = '1001';
  static const notifyCharacteristicShort = '1002';

  /// Optional compile-time override for write characteristic UUID.
  static const writeCharacteristicUuidOverride = String.fromEnvironment(
    'BLE_WRITE_CHARACTERISTIC_UUID',
    defaultValue: '',
  );

  /// Fallback write characteristics when DTU UUID is not found.
  static const fallbackWriteCharacteristicUuids = [
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e', // Nordic UART TX
    '0000ffe1-0000-1000-8000-00805f9b34fb', // HM-10 / many BLE serial modules
    '0000fff2-0000-1000-8000-00805f9b34fb',
    '0000fff3-0000-1000-8000-00805f9b34fb',
    '0000ff02-0000-1000-8000-00805f9b34fb',
  ];

  static const cccdDescriptorUuid = '00002902-0000-1000-8000-00805f9b34fb';

  /// Delay after connect / before first write (matches DTU reference app).
  static const preWriteDelay = Duration(milliseconds: 300);
}
