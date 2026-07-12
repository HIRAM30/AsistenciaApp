class AppUser {
  final String uid;
  final String nombre;
  final String correo;
  final String rol; // 'trabajador' o 'admin'
  final bool activo;

  AppUser({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.activo = true,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'trabajador',
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'activo': activo,
    };
  }

  bool get esAdmin => rol == 'admin';
}
