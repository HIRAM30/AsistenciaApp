# Control de Asistencia — App Flutter + Firebase

## 1. Requisitos previos
- Flutter instalado (`flutter --version` para confirmar)
- Cuenta de Firebase (ya la tienes ✅)
- Node.js (para la CLI de Firebase)

## 2. Instalar herramientas de Firebase
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

## 3. Conectar el proyecto
Desde la raíz de `asistencia_app`:
```bash
flutter pub get
flutterfire configure
```
Esto te preguntará qué proyecto de Firebase usar (el que ya creaste) y para
qué plataformas (elige Android y iOS al menos). Generará automáticamente
`lib/firebase_options.dart` con tus credenciales reales, reemplazando el
placeholder que incluí.

## 4. Activar servicios en Firebase Console
1. **Authentication** → Sign-in method → activa "Correo/contraseña".
2. **Firestore Database** → Crear base de datos → modo producción.
3. Pega estas reglas de seguridad (Firestore → Reglas):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function esAdmin() {
      return exists(/databases/$(database)/documents/usuarios/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.rol == 'admin';
    }

    match /usuarios/{uid} {
      allow read: if request.auth.uid == uid || esAdmin();
      allow write: if esAdmin();
    }

    match /registros/{id} {
      allow read: if request.auth != null &&
        (resource.data.uid == request.auth.uid || esAdmin());
      allow create: if request.auth != null && request.resource.data.uid == request.auth.uid;
      allow update, delete: if esAdmin();
    }

    match /zonas_trabajo/{id} {
      allow read: if request.auth != null;
      allow write: if esAdmin();
    }
  }
}
```

## 5. Crear tu primer usuario administrador
Como el registro de trabajadores solo lo puede hacer un admin desde la app,
el primer admin hay que crearlo a mano:
1. Firebase Console → Authentication → Add user (tu correo y contraseña).
2. Firestore → colección `usuarios` → crea un documento con **ID igual al
   UID** que te muestra Authentication, con estos campos:
   - `nombre`: tu nombre
   - `correo`: tu correo
   - `rol`: `admin`
   - `activo`: `true`

## 6. Permisos de ubicación

### Android (`android/app/src/main/AndroidManifest.xml`)
Agrega dentro de `<manifest>`, antes de `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (`ios/Runner/Info.plist`)
Agrega dentro del diccionario principal:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para verificar que marques asistencia dentro del área de trabajo.</string>
```

## 7. Correr la app
```bash
flutter run
```

## 8. Pendiente importante: `crearTrabajador`
La función en `lib/services/auth_service.dart` que crea trabajadores desde
el panel admin necesita una app secundaria de Firebase para no cerrar tu
sesión de admin al crear la cuenta del trabajador. Dejé el método marcado
con `UnimplementedError` y explicado ahí mismo. La forma más robusta y
recomendada en producción es mover esa lógica a una **Cloud Function**
(usando `firebase-admin`), en vez de hacerlo desde el cliente. Si quieres,
en el siguiente paso te ayudo a escribirla — es rápido.

## Estructura del proyecto
```
lib/
  models/          → AppUser, WorkZone, AttendanceRecord
  services/        → AuthService, FirestoreService, LocationService
  screens/         → LoginScreen, HomeScreen, HistoryScreen
  screens/admin/   → AdminDashboard, RecordsTab, WorkersTab, ZonesTab
  main.dart
```
