import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  final String uid;
  const HistoryScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final formato = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Mi historial')),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: firestoreService.historialTrabajador(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final registros = snapshot.data!;
          if (registros.isEmpty) {
            return const Center(child: Text('Aún no tienes registros.'));
          }
          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, i) {
              final r = registros[i];
              final esEntrada = r.tipo == TipoRegistro.entrada;
              return ListTile(
                leading: Icon(
                  esEntrada ? Icons.login : Icons.logout,
                  color: esEntrada ? Colors.green : Colors.orange,
                ),
                title: Text(esEntrada ? 'Entrada' : 'Salida'),
                subtitle: Text(formato.format(r.timestamp)),
                trailing: r.dentroDeZona
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Tooltip(
                        message: 'Fuera de zona',
                        child: Icon(Icons.warning, color: Colors.red),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
