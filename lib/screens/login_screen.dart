import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage; // Para mostrar mensajes de error

  // Metodo para iniciar sesion
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== INTENTANDO LOGIN ===');
      print('Email: ${_emailController.text.trim()}');

      final appUser = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('Resultado login: $appUser');

      if (appUser != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bienvenido'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => appUser.esAdmin
                ? const AdminDashboard()
                : HomeScreen(appUser: appUser),
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage =
              'No se encontró el perfil del usuario en la base de datos.';
        });
      }
    } on FirebaseAuthException catch (e) {
      // ESTA ES LA PARTE IMPORTANTE - MUESTRA EL ERROR REAL DE FIREBASE
      print('=== ERROR FIREBASE AUTH ===');
      print('Codigo: ${e.code}');
      print('Mensaje: ${e.message}');
      print('StackTrace: ${e.stackTrace}');

      setState(() {
        _errorMessage = 'Error [${e.code}]: ${e.message}';
      });

      // Tambien mostramos un SnackBar con el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error [${e.code}]: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Error no relacionado con Firebase
      print('=== ERROR INESPERADO ===');
      print('Error: $e');

      setState(() {
        _errorMessage = 'Error inesperado: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Metodo para crear usuario de prueba
  Future<void> _crearUsuarioPrueba() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== CREANDO USUARIO DE PRUEBA ===');

      final auth = FirebaseAuth.instance;

      // Intentar crear el usuario en Firebase Auth
      UserCredential cred;
      try {
        cred = await auth.createUserWithEmailAndPassword(
          email: 'test@test.com',
          password: '123456',
        );
        print('Usuario creado en Auth: ${cred.user!.uid}');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Si el usuario ya existe, intentar iniciar sesion
          print('Usuario ya existe, intentando login...');
          cred = await auth.signInWithEmailAndPassword(
            email: 'test@test.com',
            password: '123456',
          );
          print('Login exitoso: ${cred.user!.uid}');
        } else {
          rethrow;
        }
      }

      // Verificar si ya existe el documento en Firestore
      final docRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid);

      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // Crear documento en Firestore SOLO si no existe
        await docRef.set({
          'nombre': 'Usuario Test',
          'correo': 'test@test.com',
          'rol': 'trabajador',
          'activo': true,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
        print('Documento creado en Firestore');
      } else {
        print('Documento ya existe en Firestore');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario de prueba listo para usar'),
            backgroundColor: Colors.green,
          ),
        );

        // Autocompletar los campos
        _emailController.text = 'test@test.com';
        _passwordController.text = '123456';

        // Iniciar sesion automaticamente
        await _login();
      }
    } on FirebaseAuthException catch (e) {
      print('=== ERROR AL CREAR USUARIO ===');
      print('Codigo: ${e.code}');
      print('Mensaje: ${e.message}');

      if (mounted) {
        String mensaje;
        if (e.code == 'email-already-in-use') {
          mensaje =
              'El usuario test@test.com ya existe. Usa esas credenciales para iniciar sesion.';
          _emailController.text = 'test@test.com';
          _passwordController.text = '123456';
        } else if (e.code == 'wrong-password') {
          mensaje = 'La contrasena del usuario test@test.com es incorrecta.';
          _emailController.text = 'test@test.com';
        } else {
          mensaje = 'Error al crear usuario: ${e.message}';
        }

        setState(() {
          _errorMessage = mensaje;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('=== ERROR INESPERADO ===');
      print('Error: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Metodo para resetear contrasena
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo electronico primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un correo electronico valido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('=== RESETEANDO CONTRASENA ===');
      print('Email: $email');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://asistenciaapp.page.link/reset-password',
          handleCodeInApp: true,
          iOSBundleId: 'com.example.asistenciaapp',
          androidPackageName: 'com.example.asistenciaapp',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha enviado un enlace de recuperacion a $email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        _showEmailSentDialog(email);
      }
    } on FirebaseAuthException catch (e) {
      print('=== ERROR AL RESETEAR CONTRASENA ===');
      print('Codigo: ${e.code}');
      print('Mensaje: ${e.message}');

      if (mounted) {
        String mensaje;
        if (e.code == 'user-not-found') {
          mensaje = 'No existe una cuenta con este correo electronico.';
        } else if (e.code == 'invalid-email') {
          mensaje = 'El formato del correo electronico no es valido.';
        } else if (e.code == 'too-many-requests') {
          mensaje =
              'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
        } else {
          mensaje = 'Error: ${e.message}';
        }

        setState(() {
          _errorMessage = mensaje;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('=== ERROR INESPERADO ===');
      print('Error: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialogo de confirmacion de envio de correo
  void _showEmailSentDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Correo Enviado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hemos enviado un enlace de recuperacion a:'),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contrasena.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si no ves el correo, revisa la carpeta de SPAM.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Dialogo para recuperar contrasena
  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contrasena'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Ingresa tu correo electronico para recibir un enlace de recuperacion.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electronico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword();
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Control de Asistencia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesion para continuar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // CAMPO DE CORREO
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CAMPO DE CONTRASENA
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contrasena';
                  }
                  if (value.length < 6) {
                    return 'La contrasena debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // MOSTRAR MENSAJE DE ERROR REAL DE FIREBASE
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Olvido contrasena
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showResetPasswordDialog,
                  child: const Text('Olvidaste tu contrasena?'),
                ),
              ),
              const SizedBox(height: 16),

              // Boton de inicio de sesion
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Iniciar Sesion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Boton para crear usuario de prueba
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _crearUsuarioPrueba,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear usuario de prueba'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Mensaje informativo
              const Text(
                'Usuario de prueba: test@test.com / 123456',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}