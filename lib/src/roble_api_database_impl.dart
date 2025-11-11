import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'roble_api_config.dart';

/// Excepción genérica para errores en el cliente Roble API.
class RobleApiException implements Exception {
  final String message;
  RobleApiException(this.message);

  @override
  String toString() => 'RobleApiException: $message';
}

/// Cliente HTTP robusto para interactuar con la API Roble.
///
/// - Soporta inyección de `http.Client` para facilitar tests.
/// - Maneja timeouts, errores de red y parsing.
/// - Expone métodos CRUD y auth adaptados al backend Roble.
class RobleApiDataBase {
  final RobleApiConfig config;
  final http.Client client;

  String? _accessToken;
  String? _refreshToken;

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static const Duration timeoutDuration = Duration(seconds: 30);

  RobleApiDataBase({
    required this.config,
    http.Client? client,
  }) : client = client ?? http.Client();

  // ============================================================
  // ============= MÉTODOS INTERNOS =============================
  // ============================================================

  Uri _buildUri(String baseUrl, String endpoint,
      [Map<String, String>? queryParams]) {
    return Uri.parse('$baseUrl/$endpoint')
        .replace(queryParameters: queryParams);
  }

  Map<String, String> _mergeHeaders(
      Map<String, String>? base, Map<String, String>? extra) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (base != null) headers.addAll(base);
    if (extra != null) headers.addAll(extra);

    // ✅ Si hay token, lo agrega automáticamente como header
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Ejecuta una solicitud HTTP genérica.
  Future<dynamic> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool isAuthRequest = false,
    Map<String, String>? extraHeaders,
  }) async {
    final baseUrl = isAuthRequest ? config.authUrl : config.dataUrl;
    final uri = _buildUri(baseUrl, endpoint, queryParams);
    final headers = _mergeHeaders(
      isAuthRequest ? config.authHeaders : config.dataHeaders,
      extraHeaders,
    );

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response =
              await client.get(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await client
              .post(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
          break;
        case 'PUT':
        case 'PATCH':
          response = await client
              .put(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await client
              .delete(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
          break;
        default:
          throw RobleApiException('HTTP method $method no soportado');
      }

      // Respuesta exitosa
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return response.body;
        }
      }

      // Manejo de errores HTTP
      if (response.statusCode == 401 &&
          _refreshToken != null &&
          !isAuthRequest) {
        // 🔁 Intentamos refrescar el token automáticamente
        try {
          await refreshAccessToken();
          // Reintentamos la misma solicitud una sola vez
          return await _makeRequest(
            method,
            endpoint,
            body: body,
            queryParams: queryParams,
            isAuthRequest: isAuthRequest,
            extraHeaders: extraHeaders,
          );
        } catch (e) {
          throw RobleApiException('Token expirado y no se pudo refrescar: $e');
        }
      }

      String msg = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          msg += ': ${decoded['message']}';
        } else {
          msg += ': ${response.body}';
        }
      } catch (_) {
        msg += ': ${response.body}';
      }
      throw RobleApiException(msg);
    } on SocketException {
      throw RobleApiException('Sin conexión a internet');
    } on TimeoutException {
      throw RobleApiException('Tiempo de espera agotado');
    } on FormatException {
      throw RobleApiException('Respuesta con formato inválido');
    } catch (e) {
      throw RobleApiException('Error inesperado: $e');
    }
  }

  // ============================================================
  // ============= MÉTODOS DE AUTENTICACIÓN =====================
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _makeRequest(
      'POST',
      'login',
      body: {'email': email, 'password': password},
      isAuthRequest: true,
    );

    if (res is Map) {
      _accessToken = res['accessToken'];
      _refreshToken = res['refreshToken'];
    }

    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw RobleApiException('No hay refresh token disponible.');
    }

    final res = await _makeRequest(
      'POST',
      'refresh-token',
      body: {'refreshToken': _refreshToken},
      isAuthRequest: true,
    );

    if (res is Map && res.containsKey('accessToken')) {
      _accessToken = res['accessToken'];
    } else {
      throw RobleApiException('Respuesta inválida al refrescar el token.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _makeRequest(
      'POST',
      'signup-direct',
      body: {'email': email, 'password': password, 'name': name},
      isAuthRequest: true,
    );
    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final res = await _makeRequest(
      'POST',
      'refresh-token',
      body: {'refreshToken': refreshToken},
      isAuthRequest: true,
    );
    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }

  Future<void> logout({required String accessToken}) async {
    await _makeRequest(
      'POST',
      'logout',
      isAuthRequest: true,
      extraHeaders: {'Authorization': 'Bearer $accessToken'},
    );
  }

  // ============================================================
  // ============= MÉTODOS DE TABLAS / CRUD =====================
  // ============================================================

  Future<void> createTable(
      String tableName, List<Map<String, dynamic>> columns) async {
    await _makeRequest(
      'POST',
      'create-table',
      body: {
        'tableName': tableName,
        'description': 'Tabla $tableName creada desde cliente móvil',
        'columns': columns,
      },
    );
  }

  Future<dynamic> getTableData(String tableName) async {
    return await _makeRequest(
      'GET',
      'table-data',
      queryParams: {'schema': 'public', 'table': tableName},
    );
  }

  /// Inserta un registro y devuelve el registro insertado.
  Future<Map<String, dynamic>> create(
      String tableName, Map<String, dynamic> data) async {
    final response = await _makeRequest(
      'POST',
      'insert',
      body: {
        'tableName': tableName,
        'records': [data]
      },
    );

    if (response is Map &&
        response.containsKey('inserted') &&
        response['inserted'] is List &&
        response['inserted'].isNotEmpty) {
      return Map<String, dynamic>.from(response['inserted'][0]);
    }
    if (response is Map) return Map<String, dynamic>.from(response);
    throw RobleApiException('No se pudo insertar el registro');
  }

  Future<List<Map<String, dynamic>>> read(String tableName,
      {Map<String, dynamic>? filters}) async {
    final queryParams = <String, String>{'tableName': tableName};
    if (filters != null) {
      filters.forEach((k, v) => queryParams[k] = v.toString());
    }

    final res = await _makeRequest('GET', 'read', queryParams: queryParams);
    if (res is List) return List<Map<String, dynamic>>.from(res);
    if (res is Map && res.containsKey('data')) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> update(
      String tableName, dynamic id, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data)
      ..remove('_id')
      ..remove('id');

    final res = await _makeRequest(
      'PUT',
      'update',
      body: {
        'tableName': tableName,
        'idColumn': '_id',
        'idValue': id,
        'updates': updateData,
      },
    );
    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }

  Future<Map<String, dynamic>> delete(String tableName, dynamic id) async {
    final res = await _makeRequest(
      'DELETE',
      'delete',
      body: {
        'tableName': tableName,
        'idColumn': '_id',
        'idValue': id,
      },
    );
    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }

  // ============================================================
  // ============= MÉTODOS DE CONVENIENCIA ======================
  // ============================================================

  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    return await read(tableName);
  }

  Future<Map<String, dynamic>?> getById(String tableName, dynamic id) async {
    final results = await read(tableName, filters: {'_id': id});
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getWhere(
      String tableName, String column, dynamic value) async {
    return await read(tableName, filters: {column: value});
  }

  Future<void> simulateGet() async {}
}
