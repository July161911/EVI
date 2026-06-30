import 'package:evi/models/material_item.dart';
import 'package:evi/utils/modbus_crc16.dart';

/// Builds LED0 / out1–out8 hex command strings for shelf Bluetooth control.
class LedBluetoothCommandService {
  LedBluetoothCommandService._();

  static final LedBluetoothCommandService instance =
      LedBluetoothCommandService._();

  static const led0TotalLength = 1368;
  static const led1 = 'DD55EE0000';
  static const led3 = '0099010000';
  static const led4 = '029A';
  static const led5 = '0001';
  static const led7 = 'AABB';

  static const out1 = 'DD55EE0000000900990100000003029a000000AABB';
  static const out2 = 'DD55EE0000000A00990100000003029a000000AABB';
  static const out3 = 'DD55EE0000000B00990100000003029a000000AABB';
  static const out4 = 'DD55EE0000000C00990100000003029a000000AABB';
  static const out5 = 'DD55EE0000000D00990100000003029a000000AABB';
  static const out6 = 'DD55EE0000000E00990100000003029a000000AABB';
  static const out7 = 'DD55EE0000000F00990100000003029a000000AABB';
  static const out8 = 'DD55EE0000001000990100000003029a000000AABB';

  static const outCommands = [
    out1,
    out2,
    out3,
    out4,
    out5,
    out6,
    out7,
    out8,
  ];

  static const _led6PermutationCount = 222;
  static const _led6Unit = '000000';

  String deviceId = '';
  String led2 = '';
  String _led6 = _initialLed6();

  String get led6 => _led6;

  static String _initialLed6() {
    return List.filled(_led6PermutationCount, _led6Unit).join();
  }

  void resetLed6() {
    _led6 = _initialLed6();
  }

  /// Loads Excel row fields and rebuilds [led6] for this query only.
  void prepareFromMaterial(MaterialItem item) {
    resetLed6();
    deviceId = item.deviceId.trim();
    led2 = item.led2.trim();
    _markLed6ForQuery(led2);
  }

  void _markLed6ForQuery(String led2Value) {
    final numericLed2 = _parseLed2Numeric(led2Value);
    if (numericLed2 == null || numericLed2 < 1) {
      return;
    }

    final positions = <int>{
      (numericLed2 - 1) * 6 + 2,
      (numericLed2 - 1) * 6 + 3,
      (numericLed2 - 1) * 6 + 8,
      (numericLed2 - 1) * 6 + 9,
    };

    final chars = _led6.split('');
    for (final position in positions) {
      if (position < 0 || position >= chars.length) {
        continue;
      }
      if (chars[position] == '0') {
        chars[position] = 'F';
      }
    }
    _led6 = chars.join();
  }

  /// Numeric value of [led2] for LED6 position math (supports hex table values).
  int? _parseLed2Numeric(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return int.tryParse(trimmed);
    }

    if (RegExp(r'^[0-9A-Fa-f]+$').hasMatch(trimmed)) {
      return int.tryParse(trimmed, radix: 16);
    }

    return int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  String buildLed0() {
    return led1 + deviceId + led3 + led4 + led5 + _led6 + led7;
  }

  List<String> splitLed0IntoSegments(String led0) {
    return splitLed0IntoByteSegments(led0)
        .map(ModbusCrc16.formatBytes)
        .toList(growable: false);
  }

  /// Decodes [led0] hex, then splits into three equal binary segments.
  List<List<int>> splitLed0IntoByteSegments(String led0) {
    final bytes = _decodeLed0Hex(led0);
    if (bytes.isEmpty) {
      return const [[], [], []];
    }

    final segmentLength = bytes.length ~/ 3;
    return [
      bytes.sublist(0, segmentLength),
      bytes.sublist(segmentLength, segmentLength * 2),
      bytes.sublist(segmentLength * 2),
    ];
  }

  List<int> _decodeLed0Hex(String led0) {
    var normalized = led0.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (normalized.isEmpty) {
      return const [];
    }
    if (normalized.length.isOdd) {
      normalized = '${normalized}0';
    }
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(normalized)) {
      throw FormatException('LED0 contains non-hex characters: $led0');
    }
    return ModbusCrc16.decodeHex(normalized);
  }
}
