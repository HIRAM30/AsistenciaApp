import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Pide permisos y obtiene la posición actual con alta precisión.
  Future<Position> obtenerPosicionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw Exception('El GPS está desactivado. Actívalo para continuar.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'Permiso de ubicación denegado permanentemente. '
        'Actívalo desde los ajustes del sistema.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Distancia en metros entre dos coordenadas (fórmula de Haversine
  /// implementada internamente por Geolocator.distanceBetween).
  double distanciaMetros(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Retorna true si el punto está dentro del radio de la zona.
  bool estaDentroDeZona({
    required double lat,
    required double lng,
    required double zonaLat,
    required double zonaLng,
    required double radioMetros,
  }) {
    final distancia = distanciaMetros(lat, lng, zonaLat, zonaLng);
    return distancia <= radioMetros;
  }
}
