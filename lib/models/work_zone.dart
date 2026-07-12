class WorkZone {
  final String id;
  final String nombre;
  final double lat;
  final double lng;
  final double radioMetros;

  WorkZone({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.radioMetros,
  });

  factory WorkZone.fromMap(String id, Map<String, dynamic> data) {
    return WorkZone(
      id: id,
      nombre: data['nombre'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      radioMetros: (data['radioMetros'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'lat': lat,
      'lng': lng,
      'radioMetros': radioMetros,
    };
  }
}
