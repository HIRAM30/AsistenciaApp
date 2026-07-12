class AppUser {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;

  AppUser({
    required this.uid,
    required this.nombre,
    required this.correo,
    this.rol = 'trabajador',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'trabajador',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }

  bool get esAdmin => rol == 'admin';
  bool get esTrabajador => rol == 'trabajador';
}