# 📦 roble_api_database

Paquete para Flutter que facilita la comunicación con la plataforma Roble API.
https://roble.openlab.uninorte.edu.co/

Este paquete provee una capa ligera para autenticación y operaciones CRUD sobre las bases de datos expuestas por Roble, manteniendo una interfaz simple y adecuada para aplicaciones móviles y de escritorio con Flutter.

https://github.com/Arias3/roble_api_database

## 🚀 Instalación

Agrega la dependencia en tu proyecto Flutter:

```bash
flutter pub add roble_api_database
```

Importa el paquete donde lo necesites:

```dart
import 'package:roble_api_database/roble_api_database.dart';
```

---

## 🧭 Quick start

Ejemplo mínimo de uso (async/await):

```dart
final db = RobleApiDataBase(
	config: const RobleApiConfig(
		dataUrl: 'https://tu-api.com/database/tu-proyecto',
		authUrl: 'https://tu-api.com/auth/tu-proyecto',
	),
);

// Registrar usuario
final user = await db.register(
	email: 'usuario@email.com',
	password: 'Password123!',
	name: 'Nombre Usuario',
);

// Iniciar sesión
final session = await db.login(
	email: 'usuario@email.com',
	password: 'Password123!',
);
String accessToken = session['accessToken'];

// Cerrar sesión
await db.logout(accessToken: accessToken);

// CREATE - Crear registro
final nuevoUsuario = await db.create('usuarios', {
	'nombre': 'Ana García',
	'email': 'ana@email.com',
	'edad': 28,
});

// READ - Leer todos los registros
final usuarios = await db.read('usuarios');

// UPDATE - Actualizar registro
final actualizado = await db.update('usuarios', usuarioId, {
	'edad': 29,
});

// DELETE - Eliminar registro
final eliminado = await db.delete('usuarios', usuarioId);
```

> Nota: todos los métodos son asíncronos y pueden lanzar `RobleApiException` en caso de error de red o respuesta no esperada. Usa `try/catch` alrededor de tus llamadas.

---
## 🛠️ Contribuciones

Las contribuciones son bienvenidas. Si encuentras un bug o quieres proponer una mejora:


## Resumen

`roble_api_database` es un cliente ligero para Flutter que simplifica las peticiones HTTPS hacia la plataforma Roble. No abstrae la lógica de negocio del backend: su objetivo es facilitar el consumo de endpoints estandarizados (auth + CRUD) con manejo consistente de errores y facilidad para testing.

¡Las contribuciones y mejoras son muy bienvenidas! 🚀

