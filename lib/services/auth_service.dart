import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../firebase_options.dart';

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
  // de Auth y el documento en Firestore usando una instancia SECUNDARIA
  // de Firebase, para no cerrar la sesión del admin en el proceso.
  Future<void> crearTrabajador({
    required String nombre,
    required String correo,
    required String passwordTemporal,
  }) async {
    final secondaryApp = await _obtenerAppSecundaria();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
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
    } finally {
      // Cerramos sesión en la app secundaria SIEMPRE, incluso si algo
      // falló, para no dejar una sesión fantasma abierta ahí.
      await secondaryAuth.signOut();
    }
  }

  /// Crea (o reutiliza) una segunda instancia de Firebase con el mismo
  /// proyecto, solo para poder registrar trabajadores sin desloguear al
  /// admin. FirebaseAuth.instanceFor mantiene su propia sesión separada
  /// de la instancia principal (Firebase.app()).
  Future<FirebaseApp> _obtenerAppSecundaria() async {
    const nombreAppSecundaria = 'secondaryAdminApp';
    try {
      return Firebase.app(nombreAppSecundaria);
    } on FirebaseException {
      return Firebase.initializeApp(
        name: nombreAppSecundaria,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}