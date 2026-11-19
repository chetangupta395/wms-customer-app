import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const defaultBaseUrl = String.fromEnvironment(
  'WMS_BASE_URL',
  defaultValue: 'http://fieldora.cyberinnx.com',
);

class CustomerSession extends ChangeNotifier {
  String baseUrl = defaultBaseUrl;
  String tenant = 'demo';
  String? token;
  String name = '';
  String email = '';
  String customerName = '';
  String customerCode = '';

  bool get signedIn => token != null && token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('baseUrl') ?? baseUrl;
    tenant = prefs.getString('tenant') ?? tenant;
    token = prefs.getString('token');
    name = prefs.getString('name') ?? '';
    email = prefs.getString('email') ?? '';
    customerName = prefs.getString('customerName') ?? '';
    customerCode = prefs.getString('customerCode') ?? '';
    notifyListeners();
  }

  Future<void> remember({
    required String baseUrl,
    required String tenant,
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final customer = mapOf(user['customer']);
    this.baseUrl = normalizeUrl(baseUrl);
    this.tenant = tenant.trim().toLowerCase();
    this.token = token;
    name = '${user['name'] ?? ''}';
    email = '${user['email'] ?? ''}';
    customerName = '${customer['name'] ?? ''}';
    customerCode = '${customer['code'] ?? ''}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', this.baseUrl);
    await prefs.setString('tenant', this.tenant);
    await prefs.setString('token', token);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('customerName', customerName);
    await prefs.setString('customerCode', customerCode);
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}

String normalizeUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return value;
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'http://$value';
  }
  return value.replaceAll(RegExp(r'/+$'), '');
}

Map<String, dynamic> mapOf(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<Map<String, dynamic>> listOfMaps(dynamic value) {
  return value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}
