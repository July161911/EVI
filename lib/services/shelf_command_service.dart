import 'package:evi/utils/modbus_crc16.dart';

/// Builds shelf BLE command payloads with Modbus RTU CRC-16.
abstract final class ShelfCommandService {
  /// Frame body for out1 (CRC appended at send time).
  static const out1BodyHex = 'DD55EE0000000900990100000003029a000000';

  /// out1 command as binary bytes, including Modbus RTU CRC.
  static List<int> buildOut1Bytes() {
    return ModbusCrc16.buildBytesCommand(out1BodyHex);
  }
}
