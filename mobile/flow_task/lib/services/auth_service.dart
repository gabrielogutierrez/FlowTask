import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;

  String? userName;

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();

    api.token = prefs.getString('token');
    userName = prefs.getString('name');

    return api.token != null;
  }

  Future<void> login(
    String email,
    String password,
  ) async {
    final data = await api.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    await _save(
      data['token'] as String,
      data['name'] as String,
    );
  }

  Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    final data = await api.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    await _save(
      data['token'] as String,
      data['name'] as String,
    );
  }

  Future<void> _save(
    String token,
    String name,
  ) async {
    api.token = token;
    userName = name;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('name', name);
  }

  Future<void> logout() async {
    api.token = null;
    userName = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('name');
  }
}