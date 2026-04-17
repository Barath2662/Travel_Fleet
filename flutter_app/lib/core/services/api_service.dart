import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiService {
  Future<dynamic> get(String path, {String? token}) async {
    return _request(
      () => http.get(_uri(path), headers: _headers(token)),
      method: 'GET',
      path: path,
    );
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    return _request(
      () => http.post(_uri(path),
          headers: _headers(token), body: jsonEncode(body)),
      method: 'POST',
      path: path,
    );
  }

  Future<dynamic> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    return _request(
      () => http.put(_uri(path),
          headers: _headers(token), body: jsonEncode(body)),
      method: 'PUT',
      path: path,
    );
  }

  Future<dynamic> delete(String path, {String? token}) async {
    return _request(
      () => http.delete(_uri(path), headers: _headers(token)),
      method: 'DELETE',
      path: path,
    );
  }

  Uri _uri(String path) => Uri.parse(AppConfig.getApiEndpoint(path));

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _request(
    Future<http.Response> Function() action, {
    required String method,
    required String path,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final response =
            await action().timeout(Duration(seconds: AppConfig.apiTimeout));
        return _process(response);
      } on SocketException catch (_) {
        if (_shouldRetry(method: method, path: path, attempt: attempt)) {
          await _backoff(attempt);
          attempt++;
          continue;
        }
        throw Exception(
          'Unable to reach server at ${AppConfig.apiBaseUrl}. Please check connectivity and try again.',
        );
      } on TimeoutException catch (_) {
        if (_shouldRetry(method: method, path: path, attempt: attempt)) {
          await _backoff(attempt);
          attempt++;
          continue;
        }
        throw Exception(
          'Server is taking longer than expected (possible Render cold start). Please retry in a moment.',
        );
      } on FormatException {
        throw Exception('Invalid server response format.');
      }
    }
  }

  bool _shouldRetry({
    required String method,
    required String path,
    required int attempt,
  }) {
    if (attempt >= AppConfig.apiRetryCount) {
      return false;
    }

    if (method == 'GET') {
      return true;
    }

    // Allow retries for auth/login to improve first-launch experience on cold backend starts.
    return method == 'POST' && path.startsWith('/auth/login');
  }

  Future<void> _backoff(int attempt) {
    final multiplier = 1 << attempt;
    final delayMs = AppConfig.apiInitialRetryDelayMs * multiplier;
    return Future<void>.delayed(Duration(milliseconds: delayMs));
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
            message =
                field != null && field.isNotEmpty ? '$field: $detail' : detail;
          }
        }
      }
    }
    throw Exception(message);
  }
}
