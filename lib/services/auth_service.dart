import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> login(String correo, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: password,
    );
    if (cred.user == null) return null;
    return getAppUser(cred.user!.uid);
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  // Solo el admin debería poder crear trabajadores. Esto crea la cuenta
  // de Auth y el documento en Firestore. Requiere que el admin esté
  // autenticado; en producción esto normalmente se hace desde un backend
  // o Cloud Function para no cerrar la sesión del admin al crear un usuario.
  Future<void> crearTrabajador({
    required String nombre,
    required String correo,
    required String passwordTemporal,
  }) async {
    // Usamos una instancia secundaria para no perder la sesión del admin.
    final secondaryApp = await _crearAppSecundaria();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: passwordTemporal,
    );
    await _db.collection('usuarios').doc(cred.user!.uid).set(
      AppUser(
        uid: cred.user!.uid,
        nombre: nombre,
        correo: correo,
        rol: 'trabajador',
      ).toMap(),
    );
    await secondaryAuth.signOut();
    await secondaryApp.delete();
  }

  Future<dynamic> _crearAppSecundaria() async {
    // Import diferido para evitar dependencia circular; ver firebase_options.dart
    throw UnimplementedError(
      'Configura firebase_options.dart y descomenta esta función '
      'usando Firebase.initializeApp(name: "secondary", options: ...)',
    );
  }
}
