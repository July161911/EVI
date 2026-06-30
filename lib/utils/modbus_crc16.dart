/// Modbus RTU CRC-16 (polynomial 0xA001, init 0xFFFF).
abstract final class ModbusCrc16 {
  static const int _polynomial = 0xA001;

  /// Computes CRC-16 over [data] using the Modbus RTU algorithm.
  static int compute(Iterable<int> data) {
    var crc = 0xFFFF;
    for (final byte in data) {
      crc ^= byte & 0xFF;
      for (var bit = 0; bit < 8; bit++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ _polynomial;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  /// Returns payload bytes with CRC appended (low byte first, per Modbus RTU).
  static List<int> appendCrc(List<int> payload) {
    final crc = compute(payload);
    return [
      ...payload,
      crc & 0xFF,
      (crc >> 8) & 0xFF,
    ];
  }

  /// Encodes CRC as four uppercase hex characters (high byte first).
  static String toHexSuffix(int crc) {
    final high = (crc >> 8) & 0xFF;
    final low = crc & 0xFF;
    return '${high.toRadixString(16).padLeft(2, '0')}'
            '${low.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static List<int> decodeHex(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.isEmpty) {
      return const [];
    }
    if (cleaned.length.isOdd) {
      throw FormatException('Hex payload has odd length (${cleaned.length})');
    }
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(cleaned)) {
      throw FormatException('Hex payload contains invalid characters');
    }

    final bytes = <int>[];
    for (var index = 0; index < cleaned.length; index += 2) {
      bytes.add(int.parse(cleaned.substring(index, index + 2), radix: 16));
    }
    return bytes;
  }

  /// Returns payload bytes with Modbus RTU CRC appended (low byte first).
  static List<int> buildBytesCommand(String bodyHex) {
    final normalizedBody = bodyHex.replaceAll(RegExp(r'\s'), '').toUpperCase();
    return appendCrc(decodeHex(normalizedBody));
  }

  static String formatBytes(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  /// Builds an uppercase hex command string: [bodyHex] + CRC suffix.
  static String buildHexCommand(String bodyHex) {
    final normalizedBody = bodyHex.replaceAll(RegExp(r'\s'), '').toUpperCase();
    final payload = decodeHex(normalizedBody);
    final crc = compute(payload);
    return '$normalizedBody${toHexSuffix(crc)}';
  }
}
