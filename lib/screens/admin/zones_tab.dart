import 'package:flutter/material.dart';
import '../../models/work_zone.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class ZonesTab extends StatelessWidget {
  const ZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      body: StreamBuilder<List<WorkZone>>(
        stream: firestoreService.zonasStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final zonas = snapshot.data!;
          if (zonas.isEmpty) {
            return const Center(child: Text('Aún no hay zonas de trabajo definidas.'));
          }
          return ListView.builder(
            itemCount: zonas.length,
            itemBuilder: (context, i) {
              final z = zonas[i];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: Text(z.nombre),
                subtitle: Text('Radio: ${z.radioMetros.toStringAsFixed(0)} m'
                    ' · (${z.lat.toStringAsFixed(5)}, ${z.lng.toStringAsFixed(5)})'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => firestoreService.eliminarZona(z.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAgregar(context, firestoreService),
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Future<void> _mostrarDialogoAgregar(
      BuildContext context, FirestoreService firestoreService) async {
    final nombreCtrl = TextEditingController();
    final radioCtrl = TextEditingController(text: '100');
    final locationService = LocationService();
    bool usarUbicacionActual = true;
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nueva zona de trabajo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. Oficina Central)'),
                ),
                TextField(
                  controller: radioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Radio permitido (metros)'),
                ),
                CheckboxListTile(
                  value: usarUbicacionActual,
                  title: const Text('Usar mi ubicación actual'),
                  onChanged: (val) => setDialogState(() => usarUbicacionActual = val ?? true),
                ),
                if (!usarUbicacionActual) ...[
                  TextField(
                    controller: latCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Latitud'),
                  ),
                  TextField(
                    controller: lngCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Longitud'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  double lat, lng;
                  if (usarUbicacionActual) {
                    final pos = await locationService.obtenerPosicionActual();
                    lat = pos.latitude;
                    lng = pos.longitude;
                  } else {
                    lat = double.parse(latCtrl.text);
                    lng = double.parse(lngCtrl.text);
                  }
                  await firestoreService.crearZona(WorkZone(
                    id: '',
                    nombre: nombreCtrl.text,
                    lat: lat,
                    lng: lng,
                    radioMetros: double.parse(radioCtrl.text),
                  ));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
