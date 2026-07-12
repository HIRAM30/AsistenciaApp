import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/attendance_record.dart';
import '../../services/firestore_service.dart';

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final _firestoreService = FirestoreService();
  DateTime? _desde;
  DateTime? _hasta;
  final _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _elegirRango() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (rango != null) {
      setState(() {
        _desde = rango.start;
        _hasta = DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
      });
    }
  }

  Future<void> _exportarCSV(List<AttendanceRecord> registros) async {
    final filas = <List<String>>[
      ['Trabajador', 'Tipo', 'Fecha y hora', 'Latitud', 'Longitud', 'Dentro de zona', 'Zona'],
      ...registros.map((r) => [
            r.nombreTrabajador,
            r.tipo == TipoRegistro.entrada ? 'Entrada' : 'Salida',
            _formatoFecha.format(r.timestamp),
            r.lat.toString(),
            r.lng.toString(),
            r.dentroDeZona ? 'Sí' : 'No',
            r.zonaNombre ?? '-',
          ]),
    ];
    final csv = const ListToCsvConverter().convert(filas);
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/asistencia_${DateTime.now().millisecondsSinceEpoch}.csv');
    await archivo.writeAsString(csv);
    await Share.shareXFiles([XFile(archivo.path)], text: 'Reporte de asistencia');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _elegirRango,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _desde == null
                        ? 'Filtrar por fecha'
                        : '${DateFormat('dd/MM').format(_desde!)} - ${DateFormat('dd/MM').format(_hasta!)}',
                  ),
                ),
              ),
              if (_desde != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _desde = null;
                    _hasta = null;
                  }),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: _firestoreService.registrosAdmin(desde: _desde, hasta: _hasta),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final registros = snapshot.data!;
              if (registros.isEmpty) {
                return const Center(child: Text('Sin registros en este rango.'));
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
                    title: Text(r.nombreTrabajador),
                    subtitle: Text(
                      '${esEntrada ? "Entrada" : "Salida"} · ${_formatoFecha.format(r.timestamp)}',
                    ),
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
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Exportar a CSV'),
              onPressed: () async {
                final registros = await _firestoreService
                    .registrosAdmin(desde: _desde, hasta: _hasta)
                    .first;
                if (registros.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay registros para exportar.')),
                  );
                  return;
                }
                await _exportarCSV(registros);
              },
            ),
          ),
        ),
      ],
    );
  }
}
