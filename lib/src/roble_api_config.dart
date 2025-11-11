/// Configuración principal para el cliente Roble API.
///
/// Define las URLs base y los headers por defecto usados por
/// [RobleApiDataSource]. Esta clase es inmutable y apta para
/// inyección en entornos de producción y prueba.
///
/// Ejemplo de uso:
/// ```dart
/// final config = RobleApiConfig(
///   authUrl: 'https://api.miservidor.com/auth',
///   dataUrl: 'https://api.miservidor.com/data',
///   authHeaders: {'Content-Type': 'application/json'},
///   dataHeaders: {'Content-Type': 'application/json'},
/// );
/// ```
class RobleApiConfig {
  /// URL base para endpoints de autenticación (login, signup, refresh, etc.).
  final String authUrl;

  /// URL base para endpoints de datos (CRUD, tablas, etc.).
  final String dataUrl;

  /// Headers por defecto para peticiones de autenticación.
  final Map<String, String> authHeaders;

  /// Headers por defecto para peticiones de datos.
  final Map<String, String> dataHeaders;

  /// Constructor principal.
  const RobleApiConfig({
    required this.authUrl,
    required this.dataUrl,
    this.authHeaders = const {},
    this.dataHeaders = const {},
  });

  /// Crea una configuración básica a partir de URLs simples.
  factory RobleApiConfig.fromStrings({
    required String baseAuthUrl,
    required String baseDataUrl,
  }) {
    return RobleApiConfig(
      authUrl: baseAuthUrl,
      dataUrl: baseDataUrl,
    );
  }

  get defaultHeaders => null;

  /// Retorna una nueva instancia con un token de autenticación global.
  ///
  /// Esto es útil si quieres agregar un header de `Authorization` para
  /// todas las peticiones.
  RobleApiConfig withBearerToken(String token) {
    return RobleApiConfig(
      authUrl: authUrl,
      dataUrl: dataUrl,
      authHeaders: {
        ...authHeaders,
        'Authorization': 'Bearer $token',
      },
      dataHeaders: {
        ...dataHeaders,
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Clona la configuración actual, reemplazando solo los valores provistos.
  RobleApiConfig copyWith({
    String? authUrl,
    String? dataUrl,
    Map<String, String>? authHeaders,
    Map<String, String>? dataHeaders,
  }) {
    return RobleApiConfig(
      authUrl: authUrl ?? this.authUrl,
      dataUrl: dataUrl ?? this.dataUrl,
      authHeaders: authHeaders ?? this.authHeaders,
      dataHeaders: dataHeaders ?? this.dataHeaders,
    );
  }

  /// Valida que las URLs sean correctas.
  void validate() {
    if (!authUrl.startsWith('http')) {
      throw ArgumentError('authUrl inválida: $authUrl');
    }
    if (!dataUrl.startsWith('http')) {
      throw ArgumentError('dataUrl inválida: $dataUrl');
    }
  }

  @override
  String toString() =>
      'RobleApiConfig(authUrl: $authUrl, dataUrl: $dataUrl, authHeaders: ${authHeaders.keys}, dataHeaders: ${dataHeaders.keys})';
}
