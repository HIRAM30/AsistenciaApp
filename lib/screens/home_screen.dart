import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/work_zone.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser appUser;
  const HomeScreen({super.key, required this.appUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

  bool _procesando = false;
  TipoRegistro _proximoTipo = TipoRegistro.entrada;

  @override
  void initState() {
    super.initState();
    _cargarProximoTipo();
  }

  Future<void> _cargarProximoTipo() async {
    final ultimo = await _firestoreService.ultimoRegistroDelDia(widget.appUser.uid);
    if (ultimo != null && ultimo.tipo == TipoRegistro.entrada) {
      setState(() => _proximoTipo = TipoRegistro.salida);
    } else {
      setState(() => _proximoTipo = TipoRegistro.entrada);
    }
  }

  Future<void> _marcar() async {
    setState(() => _procesando = true);
    try {
      // 1. Obtener ubicación actual
      final posicion = await _locationService.obtenerPosicionActual();

      // 2. Revisar contra todas las zonas de trabajo activas
      final zonas = await _firestoreService.zonasStream().first;
      WorkZone? zonaCoincidente;
      for (final zona in zonas) {
        final dentro = _locationService.estaDentroDeZona(
          lat: posicion.latitude,
          lng: posicion.longitude,
          zonaLat: zona.lat,
          zonaLng: zona.lng,
          radioMetros: zona.radioMetros,
        );
        if (dentro) {
          zonaCoincidente = zona;
          break;
        }
      }

      final dentroDeZona = zonaCoincidente != null;

      if (!dentroDeZona) {
        final continuar = await _mostrarAlertaFueraDeZona();
        if (continuar != true) {
          setState(() => _procesando = false);
          return;
        }
      }

      // 3. Guardar el registro (aunque esté fuera de zona, se guarda
      // marcado como tal, para que el admin lo revise)
      final registro = AttendanceRecord(
        id: '',
        uid: widget.appUser.uid,
        nombreTrabajador: widget.appUser.nombre,
        tipo: _proximoTipo,
        timestamp: DateTime.now(),
        lat: posicion.latitude,
        lng: posicion.longitude,
        dentroDeZona: dentroDeZona,
        zonaNombre: zonaCoincidente?.nombre,
      );
      await _firestoreService.registrarAsistencia(registro);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_proximoTipo == TipoRegistro.entrada
              ? '✅ Entrada registrada'
              : '✅ Salida registrada'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarProximoTipo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<bool?> _mostrarAlertaFueraDeZona() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fuera de la zona de trabajo'),
        content: const Text(
          'No detectamos que estés dentro del área permitida. '
          'El registro se guardará marcado como "fuera de zona" '
          'para revisión del administrador. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar de todas formas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEntrada = _proximoTipo == TipoRegistro.entrada;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${widget.appUser.nombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(uid: widget.appUser.uid),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esEntrada ? Icons.login : Icons.logout,
              size: 96,
              color: esEntrada ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              esEntrada ? 'Listo para marcar entrada' : 'Listo para marcar salida',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 64),
                backgroundColor: esEntrada ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _procesando ? null : _marcar,
              child: _procesando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      esEntrada ? 'MARCAR ENTRADA' : 'MARCAR SALIDA',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
