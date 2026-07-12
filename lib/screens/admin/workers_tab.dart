import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class WorkersTab extends StatelessWidget {
  const WorkersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      body: StreamBuilder<List<AppUser>>(
        stream: firestoreService.trabajadoresStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trabajadores = snapshot.data!;
          if (trabajadores.isEmpty) {
            return const Center(child: Text('Aún no hay trabajadores registrados.'));
          }
          return ListView.builder(
            itemCount: trabajadores.length,
            itemBuilder: (context, i) {
              final t = trabajadores[i];
              return ListTile(
                leading: CircleAvatar(child: Text(t.nombre.isNotEmpty ? t.nombre[0] : '?')),
                title: Text(t.nombre),
                subtitle: Text(t.correo),
                trailing: Switch(
                  value: t.activo,
                  onChanged: (val) =>
                      firestoreService.actualizarEstadoTrabajador(t.uid, val),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAgregar(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Future<void> _mostrarDialogoAgregar(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo trabajador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: passCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña temporal')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await AuthService().crearTrabajador(
                  nombre: nombreCtrl.text,
                  correo: correoCtrl.text,
                  passwordTemporal: passCtrl.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
