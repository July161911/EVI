class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.location,
    required this.deviceId,
    required this.led2,
  });

  final String id;
  final String name;
  final String location;

  /// Excel column 4 (DeviceID).
  final String deviceId;

  /// Excel column 5 (LED2).
  final String led2;

  String get bluetoothPayload => 'MAT:$id|$location|$name';
}
