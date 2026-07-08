import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'token_storage.dart';

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConstants.baseUrl}$path');
  }

  // ─── Métodos HTTP base ───────────────────────────────────────────────────

  Future<http.Response> postForm(String path, Map<String, String> body) async {
    return _client.post(
      _buildUri(path),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
  }

  Future<http.Response> postJson(String path, Map<String, dynamic> body, {bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (withAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return _client.post(_buildUri(path), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> patchJson(String path, Map<String, dynamic> body) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    final token = await _tokenStorage.readToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return _client.patch(_buildUri(path), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> get(String path, {bool withAuth = true}) async {
    final headers = <String, String>{};
    if (withAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return _client.get(_buildUri(path), headers: headers);
  }

  Future<http.Response> delete(String path) async {
    final headers = <String, String>{};
    final token = await _tokenStorage.readToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return _client.delete(_buildUri(path), headers: headers);
  }

  // ─── Decodificadores ────────────────────────────────────────────────────

  Map<String, dynamic> decodeJson(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  List<dynamic> decodeJsonList(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  // ─── Usuarios ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await get('/users/me');
      if (response.statusCode == 200) return decodeJson(response);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getUsers() async {
    try {
      final response = await get('/users');
      if (response.statusCode == 200) return decodeJsonList(response);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<http.Response> createUser(Map<String, dynamic> body) async {
    return postJson('/users', body);
  }

  Future<http.Response> deleteUser(int userId) async {
    return delete('/users/$userId');
  }

  // ─── Parcelas ────────────────────────────────────────────────────────────

  Future<List<dynamic>?> getParcels() async {
    try {
      final response = await get('/parcels');
      if (response.statusCode == 200) return decodeJsonList(response);
      return null;
    } catch (e) {
      return null;
    }
  Future<http.Response> updateUserPassword(int userId, String newPassword) async {
    return patchJson('/users/$userId/password', {'new_password': newPassword});
  }

  Future<http.Response> createParcel(Map<String, dynamic> body) async {
    return postJson('/parcels', body);
  }

  Future<http.Response> updateParcel(int parcelId, Map<String, dynamic> body) async {
    return patchJson('/parcels/$parcelId', body);
  }

  Future<http.Response> deleteParcel(int parcelId) async {
    return delete('/parcels/$parcelId');
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    try {
      final response = await postForm('/token', {
        'username': username,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = decodeJson(response);
        final token = data['access_token'] as String;
        await _tokenStorage.saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}