import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoRegistro { entrada, salida }

class AttendanceRecord {
  final String id;
  final String uid;
  final String nombreTrabajador;
  final TipoRegistro tipo;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final bool dentroDeZona;
  final String? zonaNombre;

  AttendanceRecord({
    required this.id,
    required this.uid,
    required this.nombreTrabajador,
    required this.tipo,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.dentroDeZona,
    this.zonaNombre,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceRecord(
      id: id,
      uid: data['uid'] ?? '',
      nombreTrabajador: data['nombreTrabajador'] ?? '',
      tipo: (data['tipo'] == 'entrada') ? TipoRegistro.entrada : TipoRegistro.salida,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      dentroDeZona: data['dentroDeZona'] ?? false,
      zonaNombre: data['zonaNombre'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombreTrabajador': nombreTrabajador,
      'tipo': tipo == TipoRegistro.entrada ? 'entrada' : 'salida',
      'timestamp': Timestamp.fromDate(timestamp),
      'lat': lat,
      'lng': lng,
      'dentroDeZona': dentroDeZona,
      'zonaNombre': zonaNombre,
    };
  }
}
