class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;
  final String location;

  String get bluetoothPayload => 'MAT:$id|$location|$name';
}
