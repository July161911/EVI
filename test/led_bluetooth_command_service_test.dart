import 'package:evi/models/material_item.dart';
import 'package:evi/services/led_bluetooth_command_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    LedBluetoothCommandService.instance.resetLed6();
  });

  test('LED6 starts as 222 repetitions of 000000', () {
    expect(
      LedBluetoothCommandService.instance.led6.length,
      222 * 6,
    );
    expect(
      LedBluetoothCommandService.instance.led6.replaceAll('0', ''),
      isEmpty,
    );
  });

  test('LED2=1 replaces existing zeros with F at expected positions', () {
    const item = MaterialItem(
      id: '1',
      name: 'test',
      location: 'A1',
      deviceId: '000009',
      led2: '1',
    );

    LedBluetoothCommandService.instance.prepareFromMaterial(item);
    final led6 = LedBluetoothCommandService.instance.led6;

    expect(led6.length, 222 * 6);
    expect(led6[2], 'F');
    expect(led6[3], 'F');
    expect(led6[8], 'F');
    expect(led6[9], 'F');
    expect(led6[0], '0');
    expect(led6[1], '0');
  });

  test('LED0 uses DeviceID from table, not LED2', () {
    const item = MaterialItem(
      id: '1',
      name: 'test',
      location: 'A1',
      deviceId: '000009',
      led2: '0020',
    );

    final service = LedBluetoothCommandService.instance;
    service.prepareFromMaterial(item);

    final led0 = service.buildLed0();
    expect(
      led0.startsWith('${LedBluetoothCommandService.led1}0000090099'),
      isTrue,
    );
    expect(led0.contains('0020'), isFalse);
    expect(led0.endsWith(LedBluetoothCommandService.led7), isTrue);
  });

  test('repeated prepare for same row produces identical LED0', () {
    const item = MaterialItem(
      id: '1',
      name: 'test',
      location: 'A1',
      deviceId: '000009',
      led2: '1',
    );

    final service = LedBluetoothCommandService.instance;
    service.prepareFromMaterial(item);
    final firstLed0 = service.buildLed0();

    service.prepareFromMaterial(item);
    final secondLed0 = service.buildLed0();

    expect(firstLed0, secondLed0);
  });

  test('each prepare only applies current row LED2 markings', () {
    const itemA = MaterialItem(
      id: '1',
      name: 'test',
      location: 'A1',
      deviceId: '000009',
      led2: '1',
    );
    const itemB = MaterialItem(
      id: '2',
      name: 'test',
      location: 'A2',
      deviceId: '00000A',
      led2: '2',
    );

    final service = LedBluetoothCommandService.instance;
    service.prepareFromMaterial(itemA);
    service.prepareFromMaterial(itemB);

    expect(service.led6[2], '0');
    expect(service.led6[8], 'F');
    expect(service.buildLed0().startsWith('${LedBluetoothCommandService.led1}00000A'), isTrue);
  });

  test('LED0 splits into three binary segments', () {
    final service = LedBluetoothCommandService.instance;
    const item = MaterialItem(
      id: '1',
      name: 'test',
      location: 'A1',
      deviceId: '000009',
      led2: '1',
    );
    service.prepareFromMaterial(item);

    final segments = service.splitLed0IntoByteSegments(service.buildLed0());

    expect(segments.length, 3);
    expect(
      segments.fold<int>(0, (sum, segment) => sum + segment.length),
      service.buildLed0().length ~/ 2,
    );
  });
}
