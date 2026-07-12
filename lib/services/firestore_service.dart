import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';
import '../models/work_zone.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Zonas de trabajo ----------
  Stream<List<WorkZone>> zonasStream() {
    return _db.collection('zonas_trabajo').snapshots().map((snap) =>
        snap.docs.map((d) => WorkZone.fromMap(d.id, d.data())).toList());
  }

  Future<void> crearZona(WorkZone zona) async {
    await _db.collection('zonas_trabajo').add(zona.toMap());
  }

  Future<void> eliminarZona(String id) async {
    await _db.collection('zonas_trabajo').doc(id).delete();
  }

  // ---------- Registros de asistencia ----------
  Future<void> registrarAsistencia(AttendanceRecord record) async {
    await _db.collection('registros').add(record.toMap());
  }

  /// Historial de un trabajador específico, más reciente primero.
  Stream<List<AttendanceRecord>> historialTrabajador(String uid) {
    return _db
        .collection('registros')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AttendanceRecord.fromMap(d.id, d.data()))
            .toList());
  }

  /// Todos los registros para el panel admin, con filtros opcionales.
  Stream<List<AttendanceRecord>> registrosAdmin({
    String? uid,
    DateTime? desde,
    DateTime? hasta,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('registros');
    if (uid != null) {
      query = query.where('uid', isEqualTo: uid);
    }
    if (desde != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
    }
    if (hasta != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(hasta));
    }
    query = query.orderBy('timestamp', descending: true);

    return query.snapshots().map((snap) => snap.docs
        .map((d) => AttendanceRecord.fromMap(d.id, d.data()))
        .toList());
  }

  /// Último registro del día para saber si el trabajador debe marcar
  /// entrada o salida a continuación.
  Future<AttendanceRecord?> ultimoRegistroDelDia(String uid) async {
    final ahora = DateTime.now();
    final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);

    final snap = await _db
        .collection('registros')
        .where('uid', isEqualTo: uid)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return AttendanceRecord.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // ---------- Trabajadores ----------
  Stream<List<AppUser>> trabajadoresStream() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'trabajador')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  Future<void> actualizarEstadoTrabajador(String uid, bool activo) async {
    await _db.collection('usuarios').doc(uid).update({'activo': activo});
  }
}
