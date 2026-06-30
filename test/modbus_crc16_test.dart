import 'package:evi/services/shelf_command_service.dart';
import 'package:evi/utils/modbus_crc16.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Modbus CRC-16 matches known RTU example', () {
    final crc = ModbusCrc16.compute([0x05, 0x06, 0x05, 0x02, 0x00, 0x01]);
    expect(crc, 0xE882);
    expect(ModbusCrc16.toHexSuffix(crc), 'E882');
  });

  test('hex 00000000 decodes to four zero bytes', () {
    expect(ModbusCrc16.decodeHex('00000000'), [0, 0, 0, 0]);
  });

  test('out1 body produces binary command with CRC bytes', () {
    final command = ShelfCommandService.buildOut1Bytes();
    final bodyBytes = ModbusCrc16.decodeHex(ShelfCommandService.out1BodyHex);

    expect(command.length, bodyBytes.length + 2);
    expect(command.sublist(0, bodyBytes.length), bodyBytes);

    final crc = ModbusCrc16.compute(bodyBytes);
    expect(command[command.length - 2], crc & 0xFF);
    expect(command[command.length - 1], (crc >> 8) & 0xFF);
  });
}
