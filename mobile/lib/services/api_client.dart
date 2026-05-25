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

  Future<http.Response> postForm(String path, Map<String, String> body) async {
    return _client.post(
      _buildUri(path),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
  }

  Future<http.Response> get(String path, {bool withAuth = true}) async {
    final headers = <String, String>{};
    if (withAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return _client.get(_buildUri(path), headers: headers);
  }

  Map<String, dynamic> decodeJson(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  List<dynamic> decodeJsonList(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await postForm('/auth/login', {
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
      print('Error en el proceso de login: $e');
      return false;
    }
  }

  Future<List<dynamic>?> getParcels() async {
    try {
      final response = await get('/parcels', withAuth: true);

      if (response.statusCode == 200) {
        return decodeJsonList(response);
      }
      return null;
    } catch (e) {
      print('Error al obtener parcelas: $e');
      return null;
    }
  }
}