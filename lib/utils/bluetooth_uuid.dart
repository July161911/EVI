import 'package:evi/config/bluetooth_config.dart';

abstract final class BluetoothUuid {
  static bool matches(String uuid, String targetFull, String targetShort) {
    final lower = uuid.toLowerCase();
    final full = targetFull.toLowerCase();
    final short = targetShort.toLowerCase();
    final shortFull = '0000$short-0000-1000-8000-00805f9b34fb';

    return lower == full ||
        lower == shortFull ||
        lower.endsWith('-$short') ||
        lower == short;
  }

  static bool isWriteCharacteristic(String uuid) {
    final override = BluetoothConfig.writeCharacteristicUuidOverride.trim();
    if (override.isNotEmpty) {
      return uuid.toLowerCase() == override.toLowerCase();
    }
    return matches(
      uuid,
      BluetoothConfig.writeCharacteristicUuidFull,
      BluetoothConfig.writeCharacteristicShort,
    );
  }

  static bool isNotifyCharacteristic(String uuid) {
    return matches(
      uuid,
      BluetoothConfig.notifyCharacteristicUuidFull,
      BluetoothConfig.notifyCharacteristicShort,
    );
  }

  static bool matchesFallbackWrite(String uuid) {
    final lower = uuid.toLowerCase();
    for (final candidate in BluetoothConfig.fallbackWriteCharacteristicUuids) {
      if (lower == candidate) {
        return true;
      }
    }
    return false;
  }
}
