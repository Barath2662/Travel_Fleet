import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class ApiService {
  Future<dynamic> get(String path, {String? token}) async {
    return _request(() => http.get(_uri(path), headers: _headers(token)));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {String? token}) async {
    return _request(() => http.post(_uri(path), headers: _headers(token), body: jsonEncode(body)));
  }

  Future<dynamic> put(String path, Map<String, dynamic> body, {String? token}) async {
    return _request(() => http.put(_uri(path), headers: _headers(token), body: jsonEncode(body)));
  }

  Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _request(Future<http.Response> Function() action) async {
    try {
      final response = await action().timeout(const Duration(seconds: 15));
      return _process(response);
    } on SocketException {
      throw Exception('Unable to reach server at ${AppConstants.baseUrl}. Check backend status and API_BASE_URL.');
    } on TimeoutException {
      throw Exception('Server timeout. Check backend connectivity and try again.');
    } on FormatException {
      throw Exception('Invalid server response format.');
    }
  }

  dynamic _process(http.Response response) {
    final body = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Request failed';
    if (body is Map<String, dynamic>) {
      message = (body['message']?.toString() ?? 'Request failed');
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map<String, dynamic>) {
          final detail = first['msg']?.toString();
          final field = first['path']?.toString();
          if (detail != null && detail.isNotEmpty) {
            message = field != null && field.isNotEmpty ? '$field: $detail' : detail;
          }
        }
      }
    }
    throw Exception(message);
  }
}
