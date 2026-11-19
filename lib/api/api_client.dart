import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.session);

  final CustomerSession session;

  Future<dynamic> get(String path, [Map<String, String>? query]) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) {
    return _send('POST', path, body: body ?? const {});
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${normalizeUrl(session.baseUrl)}/api/v1/customer$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Tenant': session.tenant,
        if (session.token != null) 'Authorization': 'Bearer ${session.token}',
      });
    if (body != null) request.body = jsonEncode(body);

    http.StreamedResponse response;
    try {
      response = await http.Client()
          .send(request)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException(
        'Server se connect nahi ho saka. Internet aur server address check karein.',
      );
    }

    final text = await response.stream.bytesToString();
    dynamic decoded;
    try {
      decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    } catch (_) {
      throw ApiException(
        'Server ne valid response nahi diya (${response.statusCode}).',
      );
    }

    if (decoded is Map && decoded['success'] == false) {
      if (response.statusCode == 401 && session.signedIn) {
        await session.signOut();
      }
      throw ApiException(_message(decoded), status: response.statusCode);
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        'Request failed (${response.statusCode}).',
        status: response.statusCode,
      );
    }

    return decoded is Map ? decoded['data'] : decoded;
  }

  String _message(Map<dynamic, dynamic> decoded) {
    final errors = decoded['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return '${value.first}';
        if (value != null) return '$value';
      }
    }
    return '${decoded['message'] ?? 'Request could not be completed.'}';
  }
}
